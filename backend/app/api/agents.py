"""
智能体管理API接口
"""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.agent import Agent
from app.models.plugin import Plugin
from app.schemas.agent import (
    AgentCreate, AgentUpdate, AgentResponse, AgentList
)
from app.api.auth import get_current_user
from app.models.user import User

router = APIRouter()


def is_admin_user(user: User) -> bool:
    """判断用户是否为管理员"""
    return user.email == "admin@aiot.com" or user.username == "admin" or user.role == "admin"


def can_access_agent(agent: Agent, user: User) -> bool:
    """判断用户是否可以访问智能体"""
    if is_admin_user(user):
        return True
    # 系统内置智能体：所有用户可以访问
    if agent.is_system == 1:
        return True
    # 用户创建的智能体：只有创建者可以访问
    return agent.user_id == user.id


def can_edit_agent(agent: Agent, user: User) -> bool:
    """判断用户是否可以编辑智能体"""
    if is_admin_user(user):
        return True
    # 系统内置智能体：只有管理员可编辑
    if agent.is_system == 1:
        return False
    # 用户创建的智能体：只有创建者可编辑
    return agent.user_id == user.id


@router.post("/", response_model=AgentResponse)
@router.post("", response_model=AgentResponse)
def create_agent(
    agent: AgentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """创建新智能体"""
    # 验证插件 ID 是否存在
    if agent.plugin_ids:
        plugin_count = db.query(Plugin).filter(
            Plugin.id.in_(agent.plugin_ids),
            Plugin.is_active == 1
        ).count()
        if plugin_count != len(agent.plugin_ids):
            raise HTTPException(
                status_code=400,
                detail="部分插件不存在或已禁用"
            )
    
    # 创建智能体数据
    agent_data = agent.model_dump()
    agent_data['user_id'] = current_user.id
    agent_data['is_system'] = 0  # 普通用户创建的非系统智能体
    
    db_agent = Agent(**agent_data)
    db.add(db_agent)
    db.commit()
    db.refresh(db_agent)
    
    return db_agent


@router.get("/", response_model=AgentList)
@router.get("", response_model=AgentList)
def get_agents(
    skip: int = Query(0, ge=0, description="跳过的记录数"),
    limit: int = Query(100, ge=1, le=1000, description="返回的记录数"),
    is_active: Optional[int] = Query(None, description="是否激活筛选（1=激活，0=禁用）"),
    is_system: Optional[bool] = Query(None, description="是否系统内建筛选（仅管理员）"),
    search: Optional[str] = Query(None, description="搜索关键词"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取智能体列表"""
    query = db.query(Agent)
    
    # 权限过滤
    if is_admin_user(current_user):
        # 管理员：看到所有智能体
        if is_system is not None:
            query = query.filter(Agent.is_system == (1 if is_system else 0))
    else:
        # 普通用户：只看到系统内置智能体和自己创建的
        query = query.filter(
            (Agent.is_system == 1) | (Agent.user_id == current_user.id)
        )
    
    # 激活状态筛选
    if is_active is not None:
        query = query.filter(Agent.is_active == is_active)
    
    # 搜索
    if search:
        query = query.filter(
            (Agent.name.contains(search)) | 
            (Agent.description.contains(search))
        )
    
    # 总数
    total = query.count()
    
    # 排序和分页
    query = query.order_by(Agent.created_at.desc())
    agents = query.offset(skip).limit(limit).all()
    
    return AgentList(total=total, items=agents)


@router.get("/{agent_id}", response_model=AgentResponse)
def get_agent(
    agent_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取智能体详情"""
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    
    if not agent:
        raise HTTPException(status_code=404, detail="智能体不存在")
    
    if not can_access_agent(agent, current_user):
        raise HTTPException(status_code=403, detail="无权访问此智能体")
    
    return agent


@router.put("/{agent_id}", response_model=AgentResponse)
def update_agent(
    agent_id: int,
    agent_update: AgentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """更新智能体"""
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    
    if not agent:
        raise HTTPException(status_code=404, detail="智能体不存在")
    
    if not can_edit_agent(agent, current_user):
        raise HTTPException(status_code=403, detail="无权编辑此智能体")
    
    # 验证插件 ID 是否存在
    if agent_update.plugin_ids is not None:
        plugin_count = db.query(Plugin).filter(
            Plugin.id.in_(agent_update.plugin_ids),
            Plugin.is_active == 1
        ).count()
        if plugin_count != len(agent_update.plugin_ids):
            raise HTTPException(
                status_code=400,
                detail="部分插件不存在或已禁用"
            )
    
    # 更新字段
    update_data = agent_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(agent, field, value)
    
    db.commit()
    db.refresh(agent)
    
    return agent


@router.delete("/{agent_id}")
def delete_agent(
    agent_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """删除智能体"""
    agent = db.query(Agent).filter(Agent.id == agent_id).first()
    
    if not agent:
        raise HTTPException(status_code=404, detail="智能体不存在")
    
    if not can_edit_agent(agent, current_user):
        raise HTTPException(status_code=403, detail="无权删除此智能体")
    
    # 系统内置智能体不允许删除
    if agent.is_system == 1:
        raise HTTPException(status_code=400, detail="系统内置智能体不允许删除")
    
    db.delete(agent)
    db.commit()
    
    return {"message": "智能体已删除"}

