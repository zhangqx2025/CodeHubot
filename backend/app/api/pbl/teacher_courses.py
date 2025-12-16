from fastapi import APIRouter, Depends, HTTPException, status
from typing import Tuple
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, func
from typing import List, Optional
from pydantic import BaseModel

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_teacher
from ...core.logging_config import get_logger
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLCourse, PBLClass, PBLClassCourse, PBLClassTeacher,
    PBLGroup, PBLGroupMember, PBLUnit, PBLTask, PBLTaskProgress,
    PBLClassMember
)
from ...models.school import School
from ...utils.timezone import get_beijing_time_naive

router = APIRouter()
logger = get_logger(__name__)

# ===== 辅助函数 =====

def verify_teacher_course_permission(
    course_uuid: str,
    teacher_id: int,
    db: Session
) -> Tuple[PBLCourse, PBLClassTeacher]:
    """
    验证教师是否有权限访问该课程
    
    Args:
        course_uuid: 课程UUID
        teacher_id: 教师ID
        db: 数据库会话
    
    Returns:
        (课程对象, 教师班级关联对象)
    
    Raises:
        HTTPException: 权限验证失败时抛出
    """
    # 查询课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="课程不存在"
        )
    
    # 检查课程是否关联班级
    if not course.class_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该课程未关联班级"
        )
    
    # 验证教师是否负责该班级
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == teacher_id
    ).first()
    
    if not teacher_rel:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限访问该课程"
        )
    
    return course, teacher_rel

# ===== Pydantic Schemas =====

class GroupCreateRequest(BaseModel):
    """创建小组请求"""
    name: str
    description: Optional[str] = None
    max_members: Optional[int] = 6

class GroupUpdateRequest(BaseModel):
    """更新小组请求"""
    name: Optional[str] = None
    description: Optional[str] = None
    max_members: Optional[int] = None
    leader_id: Optional[int] = None

class GroupMemberAddRequest(BaseModel):
    """添加小组成员请求"""
    user_ids: List[int]

class HomeworkGradeRequest(BaseModel):
    """作业批改请求"""
    score: int
    feedback: Optional[str] = None

# ===== 课程管理 =====

@router.get("/courses")
def get_teacher_courses(
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取教师负责的所有课程列表
    
    逻辑：
    1. 通过 pbl_class_teachers 表查询教师负责的班级
    2. 通过班级ID查询对应的课程（pbl_courses 表的 class_id）
    """
    logger.info(f"教师 {current_teacher.username} (ID: {current_teacher.id}) 查询课程列表")
    
    # 1. 查询教师负责的班级
    class_relations = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.teacher_id == current_teacher.id
    ).all()
    
    if not class_relations:
        return success_response(data=[], message="暂无负责的班级")
    
    class_ids = [rel.class_id for rel in class_relations]
    
    # 2. 查询这些班级对应的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id.in_(class_ids)
    ).all()
    
    if not courses:
        return success_response(data=[], message="暂无负责的课程")
    
    result = []
    for course in courses:
        # 获取课程关联的班级信息
        class_info = None
        if course.class_id:
            pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
            if pbl_class:
                class_info = {
                    "id": pbl_class.id,
                    "uuid": pbl_class.uuid,
                    "name": pbl_class.name,
                    "class_type": pbl_class.class_type,
                    "current_members": pbl_class.current_members
                }
        
        # 统计单元数量
        unit_count = db.query(func.count(PBLUnit.id)).filter(
            PBLUnit.course_id == course.id
        ).scalar()
        
        # 获取教师在该班级中的角色
        teacher_rel = next((rel for rel in class_relations if rel.class_id == course.class_id), None)
        
        result.append({
            "id": course.id,
            "uuid": course.uuid,
            "title": course.title,
            "description": course.description,
            "cover_image": course.cover_image,
            "difficulty": course.difficulty,
            "status": course.status,
            "duration": course.duration,
            "start_date": course.start_date.isoformat() if course.start_date else None,
            "end_date": course.end_date.isoformat() if course.end_date else None,
            "unit_count": unit_count,
            "class": class_info,
            "is_primary": teacher_rel.is_primary if teacher_rel else False,
            "subject": teacher_rel.subject if teacher_rel else None,
            "role": teacher_rel.role if teacher_rel else 'assistant',
            "created_at": course.created_at.isoformat() if course.created_at else None
        })
    
    logger.info(f"教师 {current_teacher.username} 共有 {len(result)} 门课程")
    return success_response(data=result)

@router.get("/courses/{course_uuid}")
def get_teacher_course_detail(
    course_uuid: str,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取课程详情（包含班级信息）"""
    logger.info(f"教师 {current_teacher.username} 查询课程详情: {course_uuid}")
    
    # 查询课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 验证教师是否负责该课程（通过班级关联）
    if not course.class_id:
        return error_response(
            message="该课程未关联班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(
            message="无权限访问该课程",
            code=403,
            status_code=status.HTTP_403_FORBIDDEN
        )
    
    # 获取班级信息
    class_info = None
    if course.class_id:
        pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
        if pbl_class:
            # 统计小组数量
            group_count = db.query(func.count(PBLGroup.id)).filter(
                PBLGroup.class_id == pbl_class.id
            ).scalar()
            
            class_info = {
                "id": pbl_class.id,
                "uuid": pbl_class.uuid,
                "name": pbl_class.name,
                "class_type": pbl_class.class_type,
                "description": pbl_class.description,
                "current_members": pbl_class.current_members,
                "max_students": pbl_class.max_students,
                "group_count": group_count,
                "created_at": pbl_class.created_at.isoformat() if pbl_class.created_at else None
            }
    
    # 获取单元列表
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    unit_list = []
    for unit in units:
        # 统计任务数量
        task_count = db.query(func.count(PBLTask.id)).filter(
            PBLTask.unit_id == unit.id
        ).scalar()
        
        unit_list.append({
            "id": unit.id,
            "uuid": unit.uuid,
            "title": unit.title,
            "description": unit.description,
            "order": unit.order,
            "status": unit.status,
            "task_count": task_count,
            "estimated_duration": unit.estimated_duration
        })
    
    result = {
        "id": course.id,
        "uuid": course.uuid,
        "title": course.title,
        "description": course.description,
        "cover_image": course.cover_image,
        "difficulty": course.difficulty,
        "status": course.status,
        "duration": course.duration,
        "start_date": course.start_date.isoformat() if course.start_date else None,
        "end_date": course.end_date.isoformat() if course.end_date else None,
        "class": class_info,
        "units": unit_list,
        "teacher_role": {
            "is_primary": teacher_rel.is_primary,
            "role": teacher_rel.role,
            "subject": teacher_rel.subject
        },
        "created_at": course.created_at.isoformat() if course.created_at else None
    }
    
    return success_response(data=result)

# ===== 分组管理 =====

@router.get("/courses/{course_uuid}/groups")
def get_course_groups(
    course_uuid: str,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取课程的所有小组"""
    logger.info(f"教师 {current_teacher.username} 查询课程小组: {course_uuid}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限访问", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询小组
    groups = db.query(PBLGroup).filter(
        or_(PBLGroup.course_id == course.id, PBLGroup.class_id == course.class_id)
    ).all()
    
    result = []
    for group in groups:
        # 查询小组成员
        members = db.query(PBLGroupMember, User).join(
            User, PBLGroupMember.user_id == User.id
        ).filter(
            PBLGroupMember.group_id == group.id,
            PBLGroupMember.is_active == 1
        ).all()
        
        member_list = []
        for member_rel, user in members:
            member_list.append({
                "id": user.id,
                "name": user.name or user.real_name,
                "username": user.username,
                "student_number": user.student_number,
                "role": member_rel.role,
                "joined_at": member_rel.joined_at.isoformat() if member_rel.joined_at else None
            })
        
        result.append({
            "id": group.id,
            "uuid": group.uuid,
            "name": group.name,
            "description": group.description,
            "leader_id": group.leader_id,
            "max_members": group.max_members,
            "current_members": len(member_list),
            "members": member_list,
            "is_active": group.is_active,
            "created_at": group.created_at.isoformat() if group.created_at else None
        })
    
    return success_response(data=result)

@router.post("/courses/{course_uuid}/groups")
def create_course_group(
    course_uuid: str,
    group_data: GroupCreateRequest,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """创建新小组"""
    logger.info(f"教师 {current_teacher.username} 创建小组: {group_data.name}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 创建小组
    import uuid
    new_group = PBLGroup(
        uuid=str(uuid.uuid4()),
        class_id=course.class_id,
        course_id=course.id,
        name=group_data.name,
        description=group_data.description,
        max_members=group_data.max_members or 6,
        is_active=1
    )
    
    db.add(new_group)
    db.commit()
    db.refresh(new_group)
    
    logger.info(f"小组创建成功: {new_group.name} (ID: {new_group.id})")
    
    return success_response(
        data={
            "id": new_group.id,
            "uuid": new_group.uuid,
            "name": new_group.name,
            "description": new_group.description,
            "max_members": new_group.max_members
        },
        message="小组创建成功"
    )

@router.put("/courses/{course_uuid}/groups/{group_id}")
def update_course_group(
    course_uuid: str,
    group_id: int,
    group_data: GroupUpdateRequest,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """更新小组信息"""
    logger.info(f"教师 {current_teacher.username} 更新小组: {group_id}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.id == group_id).first()
    if not group:
        return error_response(message="小组不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 更新小组信息
    if group_data.name is not None:
        group.name = group_data.name
    if group_data.description is not None:
        group.description = group_data.description
    if group_data.max_members is not None:
        group.max_members = group_data.max_members
    if group_data.leader_id is not None:
        group.leader_id = group_data.leader_id
    
    db.commit()
    db.refresh(group)
    
    logger.info(f"小组更新成功: {group.name} (ID: {group.id})")
    
    return success_response(message="小组更新成功")

@router.delete("/courses/{course_uuid}/groups/{group_id}")
def delete_course_group(
    course_uuid: str,
    group_id: int,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """删除小组"""
    logger.info(f"教师 {current_teacher.username} 删除小组: {group_id}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.id == group_id).first()
    if not group:
        return error_response(message="小组不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 删除小组（软删除：设置为非激活状态）
    group.is_active = 0
    db.commit()
    
    logger.info(f"小组删除成功: {group.name} (ID: {group.id})")
    
    return success_response(message="小组删除成功")

@router.post("/courses/{course_uuid}/groups/{group_id}/members")
def add_group_members(
    course_uuid: str,
    group_id: int,
    member_data: GroupMemberAddRequest,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """添加小组成员"""
    logger.info(f"教师 {current_teacher.username} 添加小组成员")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询小组
    group = db.query(PBLGroup).filter(PBLGroup.id == group_id).first()
    if not group:
        return error_response(message="小组不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 添加成员
    added_count = 0
    for user_id in member_data.user_ids:
        # 检查是否已存在
        existing = db.query(PBLGroupMember).filter(
            PBLGroupMember.group_id == group_id,
            PBLGroupMember.user_id == user_id,
            PBLGroupMember.is_active == 1
        ).first()
        
        if not existing:
            new_member = PBLGroupMember(
                group_id=group_id,
                user_id=user_id,
                role='member',
                is_active=1
            )
            db.add(new_member)
            added_count += 1
    
    db.commit()
    
    logger.info(f"成功添加 {added_count} 名成员到小组 {group.name}")
    
    return success_response(message=f"成功添加 {added_count} 名成员")

@router.delete("/courses/{course_uuid}/groups/{group_id}/members/{user_id}")
def remove_group_member(
    course_uuid: str,
    group_id: int,
    user_id: int,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """移除小组成员"""
    logger.info(f"教师 {current_teacher.username} 移除小组成员: user_id={user_id}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询成员记录
    member = db.query(PBLGroupMember).filter(
        PBLGroupMember.group_id == group_id,
        PBLGroupMember.user_id == user_id
    ).first()
    
    if not member:
        return error_response(message="成员不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 移除成员（软删除）
    member.is_active = 0
    db.commit()
    
    logger.info(f"成功移除小组成员: user_id={user_id}")
    
    return success_response(message="成员移除成功")

# ===== 班级成员管理 =====

@router.get("/courses/{course_uuid}/members")
def get_class_members(
    course_uuid: str,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取班级成员列表"""
    logger.info(f"教师 {current_teacher.username} 查询班级成员: {course_uuid}")
    
    # 验证权限
    try:
        course, teacher_rel = verify_teacher_course_permission(course_uuid, current_teacher.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 获取班级信息
    pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
    if not pbl_class:
        return error_response(message="班级不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 获取班级成员
    members_query = db.query(PBLClassMember, User).join(
        User, PBLClassMember.student_id == User.id
    ).filter(
        PBLClassMember.class_id == course.class_id,
        PBLClassMember.is_active == 1
    ).all()
    
    members_list = []
    for member_rel, user in members_query:
        # 查询学生所在小组
        group_member = db.query(PBLGroupMember, PBLGroup).join(
            PBLGroup, PBLGroupMember.group_id == PBLGroup.id
        ).filter(
            PBLGroupMember.user_id == user.id,
            PBLGroup.class_id == course.class_id,
            PBLGroupMember.is_active == 1,
            PBLGroup.is_active == 1
        ).first()
        
        group_name = None
        if group_member:
            _, group = group_member
            group_name = group.name
        
        members_list.append({
            "id": user.id,
            "name": user.name or user.real_name,
            "student_number": user.student_number,
            "phone": user.phone,
            "email": user.email,
            "group_name": group_name,
            "joined_at": member_rel.joined_at.isoformat() if member_rel.joined_at else None
        })
    
    return success_response(data={
        "class_info": {
            "id": pbl_class.id,
            "uuid": pbl_class.uuid,
            "name": pbl_class.name,
            "class_type": pbl_class.class_type,
            "current_members": pbl_class.current_members
        },
        "members": members_list,
        "total": len(members_list)
    })

# ===== 学习进度查询 =====

@router.get("/courses/{course_uuid}/units")
def get_course_units(
    course_uuid: str,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取课程的所有单元列表（用于进度和作业管理）"""
    logger.info(f"教师 {current_teacher.username} 查询课程单元: {course_uuid}")
    
    # 验证权限
    try:
        course, teacher_rel = verify_teacher_course_permission(course_uuid, current_teacher.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 获取所有单元
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    result = []
    for unit in units:
        # 统计任务数量
        task_count = db.query(func.count(PBLTask.id)).filter(
            PBLTask.unit_id == unit.id
        ).scalar()
        
        result.append({
            "id": unit.id,
            "uuid": unit.uuid,
            "title": unit.title,
            "description": unit.description,
            "order": unit.order,
            "status": unit.status,
            "task_count": task_count,
            "estimated_duration": unit.estimated_duration,
            "open_from": unit.open_from.isoformat() if unit.open_from else None
        })
    
    return success_response(data=result)

@router.get("/courses/{course_uuid}/units/{unit_id}/progress")
def get_unit_progress(
    course_uuid: str,
    unit_id: int,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取指定单元的学习进度（按学生展示）"""
    logger.info(f"教师 {current_teacher.username} 查询单元进度: course={course_uuid}, unit={unit_id}")
    
    # 验证权限
    try:
        course, teacher_rel = verify_teacher_course_permission(course_uuid, current_teacher.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 查询单元
    unit = db.query(PBLUnit).filter(
        PBLUnit.id == unit_id,
        PBLUnit.course_id == course.id
    ).first()
    
    if not unit:
        return error_response(message="单元不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 获取单元的所有任务
    tasks = db.query(PBLTask).filter(
        PBLTask.unit_id == unit.id
    ).order_by(PBLTask.order).all()
    
    # 获取班级成员
    students = db.query(User).join(
        PBLClassMember, User.id == PBLClassMember.student_id
    ).filter(
        PBLClassMember.class_id == course.class_id,
        PBLClassMember.is_active == 1
    ).all()
    
    # 统计每个学生的进度
    student_progress = []
    for student in students:
        completed_tasks = 0
        task_details = []
        
        for task in tasks:
            # 查询任务进度（只要提交了就算完成）
            progress = db.query(PBLTaskProgress).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.user_id == student.id
            ).first()
            
            is_completed = False
            submitted_at = None
            
            if progress and progress.status in ['review', 'completed']:
                is_completed = True
                submitted_at = progress.submitted_at
                completed_tasks += 1
            
            task_details.append({
                "task_id": task.id,
                "task_title": task.title,
                "task_type": task.type,
                "is_completed": is_completed,
                "submitted_at": submitted_at.isoformat() if submitted_at else None
            })
        
        progress_percentage = (completed_tasks / len(tasks) * 100) if tasks else 0
        
        student_progress.append({
            "student_id": student.id,
            "student_name": student.name or student.real_name,
            "student_number": student.student_number,
            "completed_tasks": completed_tasks,
            "total_tasks": len(tasks),
            "progress_percentage": round(progress_percentage, 2),
            "task_details": task_details
        })
    
    return success_response(data={
        "unit": {
            "id": unit.id,
            "uuid": unit.uuid,
            "title": unit.title,
            "description": unit.description,
            "order": unit.order,
            "task_count": len(tasks)
        },
        "students": student_progress
    })

@router.get("/courses/{course_uuid}/progress")
def get_course_progress(
    course_uuid: str,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取课程学习进度统计（已废弃，请使用单元级别的进度查询）"""
    logger.info(f"教师 {current_teacher.username} 查询课程进度: {course_uuid}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限访问", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 获取班级成员
    students = []
    if course.class_id:
        class_members = db.query(PBLClassMember, User).join(
            User, PBLClassMember.student_id == User.id
        ).filter(
            PBLClassMember.class_id == course.class_id,
            PBLClassMember.is_active == 1
        ).all()
        
        students = [user for _, user in class_members]
    
    # 获取所有单元
    units = db.query(PBLUnit).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order).all()
    
    # 统计每个学生的进度
    student_progress = []
    for student in students:
        completed_units = 0
        total_tasks = 0
        completed_tasks = 0
        
        for unit in units:
            # 获取单元的所有任务
            unit_tasks = db.query(PBLTask).filter(
                PBLTask.unit_id == unit.id
            ).all()
            
            total_tasks += len(unit_tasks)
            
            # 统计学生完成的任务
            for task in unit_tasks:
                progress = db.query(PBLTaskProgress).filter(
                    PBLTaskProgress.task_id == task.id,
                    PBLTaskProgress.user_id == student.id,
                    PBLTaskProgress.status == 'completed'
                ).first()
                
                if progress:
                    completed_tasks += 1
            
            # 判断单元是否完成（所有任务都完成）
            if len(unit_tasks) > 0:
                unit_completed = db.query(func.count(PBLTaskProgress.id)).filter(
                    PBLTaskProgress.task_id.in_([t.id for t in unit_tasks]),
                    PBLTaskProgress.user_id == student.id,
                    PBLTaskProgress.status == 'completed'
                ).scalar()
                
                if unit_completed == len(unit_tasks):
                    completed_units += 1
        
        progress_percentage = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        student_progress.append({
            "student_id": student.id,
            "student_name": student.name or student.real_name,
            "student_number": student.student_number,
            "completed_units": completed_units,
            "total_units": len(units),
            "completed_tasks": completed_tasks,
            "total_tasks": total_tasks,
            "progress_percentage": round(progress_percentage, 2)
        })
    
    # 课程整体统计
    overall_stats = {
        "total_students": len(students),
        "total_units": len(units),
        "average_progress": round(sum([s['progress_percentage'] for s in student_progress]) / len(student_progress), 2) if student_progress else 0
    }
    
    return success_response(data={
        "overall": overall_stats,
        "students": student_progress
    })

# ===== 作业管理 =====

@router.get("/courses/{course_uuid}/units/{unit_id}/homework")
def get_unit_homework(
    course_uuid: str,
    unit_id: int,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取指定单元的作业提交情况（按学生展示）"""
    logger.info(f"教师 {current_teacher.username} 查询单元作业: course={course_uuid}, unit={unit_id}")
    
    # 验证权限
    try:
        course, teacher_rel = verify_teacher_course_permission(course_uuid, current_teacher.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 查询单元
    unit = db.query(PBLUnit).filter(
        PBLUnit.id == unit_id,
        PBLUnit.course_id == course.id
    ).first()
    
    if not unit:
        return error_response(message="单元不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 获取单元的所有任务
    tasks = db.query(PBLTask).filter(
        PBLTask.unit_id == unit.id
    ).order_by(PBLTask.order).all()
    
    # 获取班级成员
    students = db.query(User).join(
        PBLClassMember, User.id == PBLClassMember.student_id
    ).filter(
        PBLClassMember.class_id == course.class_id,
        PBLClassMember.is_active == 1
    ).all()
    
    # 统计每个学生的作业提交情况
    student_homework = []
    for student in students:
        submitted_count = 0
        task_submissions = []
        
        for task in tasks:
            # 查询任务进度（只要提交了就算完成）
            progress = db.query(PBLTaskProgress).filter(
                PBLTaskProgress.task_id == task.id,
                PBLTaskProgress.user_id == student.id
            ).first()
            
            is_submitted = False
            submitted_at = None
            status_text = "未提交"
            score = None
            feedback = None
            
            if progress:
                if progress.status in ['review', 'completed']:
                    is_submitted = True
                    submitted_at = progress.submitted_at
                    submitted_count += 1
                    
                    if progress.status == 'review':
                        status_text = "待批改"
                    elif progress.status == 'completed':
                        status_text = "已批改"
                        score = progress.score
                        feedback = progress.feedback
            
            task_submissions.append({
                "task_id": task.id,
                "task_title": task.title,
                "task_type": task.type,
                "is_required": task.is_required,
                "deadline": task.deadline.isoformat() if task.deadline else None,
                "is_submitted": is_submitted,
                "status": status_text,
                "submitted_at": submitted_at.isoformat() if submitted_at else None,
                "score": score,
                "feedback": feedback,
                "progress_id": progress.id if progress else None
            })
        
        submission_rate = (submitted_count / len(tasks) * 100) if tasks else 0
        
        student_homework.append({
            "student_id": student.id,
            "student_name": student.name or student.real_name,
            "student_number": student.student_number,
            "submitted_count": submitted_count,
            "total_tasks": len(tasks),
            "submission_rate": round(submission_rate, 2),
            "task_submissions": task_submissions
        })
    
    return success_response(data={
        "unit": {
            "id": unit.id,
            "uuid": unit.uuid,
            "title": unit.title,
            "description": unit.description,
            "order": unit.order,
            "task_count": len(tasks)
        },
        "students": student_homework
    })

@router.get("/courses/{course_uuid}/homework")
def get_course_homework(
    course_uuid: str,
    unit_id: Optional[int] = None,
    status: Optional[str] = None,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取课程作业列表（已废弃，请使用单元级别的作业查询）"""
    logger.info(f"教师 {current_teacher.username} 查询课程作业: {course_uuid}")
    
    # 验证权限
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限访问", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询任务
    query = db.query(PBLTask, PBLUnit).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id
    )
    
    if unit_id:
        query = query.filter(PBLTask.unit_id == unit_id)
    
    tasks = query.order_by(PBLUnit.order, PBLTask.order).all()
    
    result = []
    for task, unit in tasks:
        # 统计提交情况
        total_submissions = db.query(func.count(PBLTaskProgress.id)).filter(
            PBLTaskProgress.task_id == task.id,
            PBLTaskProgress.status.in_(['review', 'completed'])
        ).scalar()
        
        pending_review = db.query(func.count(PBLTaskProgress.id)).filter(
            PBLTaskProgress.task_id == task.id,
            PBLTaskProgress.status == 'review'
        ).scalar()
        
        graded = db.query(func.count(PBLTaskProgress.id)).filter(
            PBLTaskProgress.task_id == task.id,
            PBLTaskProgress.status == 'completed',
            PBLTaskProgress.score.isnot(None)
        ).scalar()
        
        result.append({
            "task_id": task.id,
            "task_uuid": task.uuid,
            "task_title": task.title,
            "task_type": task.type,
            "difficulty": task.difficulty,
            "deadline": task.deadline.isoformat() if task.deadline else None,
            "is_required": task.is_required,
            "unit_id": unit.id,
            "unit_title": unit.title,
            "statistics": {
                "total_submissions": total_submissions,
                "pending_review": pending_review,
                "graded": graded
            }
        })
    
    return success_response(data=result)

@router.get("/homework/{task_id}/submissions")
def get_homework_submissions(
    task_id: int,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """获取作业提交列表"""
    logger.info(f"教师 {current_teacher.username} 查询作业提交: task_id={task_id}")
    
    # 查询任务
    task = db.query(PBLTask).filter(PBLTask.id == task_id).first()
    if not task:
        return error_response(message="任务不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 验证权限
    unit = db.query(PBLUnit).filter(PBLUnit.id == task.unit_id).first()
    course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限访问", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 查询提交记录
    submissions = db.query(PBLTaskProgress, User).join(
        User, PBLTaskProgress.user_id == User.id
    ).filter(
        PBLTaskProgress.task_id == task_id
    ).all()
    
    result = []
    for progress, user in submissions:
        result.append({
            "id": progress.id,
            "student_id": user.id,
            "student_name": user.name or user.real_name,
            "student_number": user.student_number,
            "status": progress.status,
            "progress": progress.progress,
            "submission": progress.submission,
            "submitted_at": progress.submitted_at.isoformat() if progress.submitted_at else None,
            "score": progress.score,
            "feedback": progress.feedback,
            "graded_at": progress.graded_at.isoformat() if progress.graded_at else None
        })
    
    return success_response(data=result)

@router.put("/homework/{progress_id}/grade")
def grade_homework(
    progress_id: int,
    grade_data: HomeworkGradeRequest,
    current_teacher: Admin = Depends(get_current_teacher),
    db: Session = Depends(get_db)
):
    """批改作业"""
    logger.info(f"教师 {current_teacher.username} 批改作业: progress_id={progress_id}")
    
    # 查询提交记录
    progress = db.query(PBLTaskProgress).filter(PBLTaskProgress.id == progress_id).first()
    if not progress:
        return error_response(message="提交记录不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 验证权限
    task = db.query(PBLTask).filter(PBLTask.id == progress.task_id).first()
    unit = db.query(PBLUnit).filter(PBLUnit.id == task.unit_id).first()
    course = db.query(PBLCourse).filter(PBLCourse.id == unit.course_id).first()
    
    teacher_rel = db.query(PBLClassTeacher).filter(
        PBLClassTeacher.class_id == course.class_id,
        PBLClassTeacher.teacher_id == current_teacher.id
    ).first()
    
    if not teacher_rel:
        return error_response(message="无权限操作", code=403, status_code=status.HTTP_403_FORBIDDEN)
    
    # 更新评分
    progress.score = grade_data.score
    progress.feedback = grade_data.feedback
    progress.status = 'completed'
    progress.graded_by = current_teacher.id
    progress.graded_at = get_beijing_time_naive()
    
    db.commit()
    
    logger.info(f"作业批改成功: progress_id={progress_id}, score={grade_data.score}")
    
    return success_response(message="批改成功")
