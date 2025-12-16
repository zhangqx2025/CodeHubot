from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid as uuid_lib
import os
import re
import imghdr
from pathlib import Path
from datetime import datetime

from ...db.session import SessionLocal
from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_admin
from ...models.admin import Admin
from ...models.pbl import (
    PBLCourse, PBLUnit, PBLResource, PBLTask, 
    PBLCourseTemplate, PBLUnitTemplate, PBLResourceTemplate, PBLTaskTemplate
)
from ...schemas.pbl import (
    CourseBase, Course, 
    CourseTemplate, CourseTemplateCreate, CourseTemplateUpdate, CourseTemplateWithDetails,
    UnitTemplate, UnitTemplateCreate, UnitTemplateUpdate, UnitTemplateWithDetails,
    ResourceTemplate, ResourceTemplateCreate, ResourceTemplateUpdate,
    TaskTemplate, TaskTemplateCreate, TaskTemplateUpdate,
    UnitBase, UnitCreate, UnitUpdate, Unit,
    ResourceBase, ResourceCreate, ResourceUpdate, Resource,
    TaskBase, TaskCreate, TaskUpdate, Task
)

router = APIRouter()

def serialize_course(course: PBLCourse) -> dict:
    """将 Course 模型转换为字典"""
    return Course.model_validate(course).model_dump(mode='json')

def serialize_courses(courses: List[PBLCourse]) -> List[dict]:
    """将 Course 模型列表转换为字典列表"""
    return [serialize_course(course) for course in courses]

@router.get("")
def get_courses(
    skip: int = 0,
    limit: int = 100,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程列表"""
    query = db.query(PBLCourse)
    
    if status:
        query = query.filter(PBLCourse.status == status)
    
    courses = query.offset(skip).limit(limit).all()
    return success_response(data=serialize_courses(courses))

@router.post("")
def create_course(
    course_data: CourseBase,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建课程"""
    new_course = PBLCourse(
        title=course_data.title,
        description=course_data.description,
        cover_image=course_data.cover_image,
        duration=course_data.duration,
        difficulty=course_data.difficulty or 'beginner',
        status='draft',
        creator_id=current_admin.id
    )
    
    db.add(new_course)
    db.commit()
    db.refresh(new_course)
    
    return success_response(data=serialize_course(new_course), message="课程创建成功")

@router.get("/templates")
def get_course_templates(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=1000),
    search: Optional[str] = Query(None, description="搜索关键词（标题或编码）"),
    category: Optional[str] = None,
    is_public: Optional[int] = None,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板列表（支持分页和搜索）"""
    query = db.query(PBLCourseTemplate)
    
    # 搜索
    if search:
        query = query.filter(
            (PBLCourseTemplate.title.like(f'%{search}%')) | 
            (PBLCourseTemplate.template_code.like(f'%{search}%'))
        )
    
    # 筛选
    if category:
        query = query.filter(PBLCourseTemplate.category == category)
    
    if is_public is not None:
        query = query.filter(PBLCourseTemplate.is_public == is_public)
    
    # 总数
    total = query.count()
    
    # 按使用次数和创建时间排序，并分页
    templates = query.order_by(
        PBLCourseTemplate.usage_count.desc(),
        PBLCourseTemplate.created_at.desc()
    ).offset((page - 1) * page_size).limit(page_size).all()
    
    # 序列化模板列表
    templates_data = [CourseTemplate.model_validate(template).model_dump(mode='json') for template in templates]
    
    return success_response(data={
        "items": templates_data,
        "total": total,
        "page": page,
        "page_size": page_size
    })


@router.post("/templates")
def create_course_template(
    template_data: CourseTemplateCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """创建课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以创建课程模板")
    
    # 检查模板编码是否已存在
    existing = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.template_code == template_data.template_code
    ).first()
    if existing:
        return error_response(
            message=f"模板编码 {template_data.template_code} 已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建模板
    new_template = PBLCourseTemplate(
        uuid=str(uuid_lib.uuid4()),
        template_code=template_data.template_code,
        title=template_data.title,
        description=template_data.description,
        cover_image=template_data.cover_image,
        duration=template_data.duration,
        difficulty=template_data.difficulty or 'beginner',
        category=template_data.category,
        version=template_data.version or '1.0.0',
        is_public=template_data.is_public,
        creator_id=current_admin.id,
        usage_count=0
    )
    
    db.add(new_template)
    db.commit()
    db.refresh(new_template)
    
    template_result = CourseTemplate.model_validate(new_template).model_dump(mode='json')
    return success_response(data=template_result, message="课程模板创建成功")


@router.get("/templates/{template_uuid}")
def get_course_template(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板详情"""
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    template_data = CourseTemplate.model_validate(template).model_dump(mode='json')
    return success_response(data=template_data)


@router.put("/templates/{template_uuid}")
def update_course_template(
    template_uuid: str,
    template_data: CourseTemplateUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以修改课程模板")
    
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 如果要修改模板编码，检查是否与其他模板冲突
    if template_data.template_code and template_data.template_code != template.template_code:
        existing = db.query(PBLCourseTemplate).filter(
            PBLCourseTemplate.template_code == template_data.template_code,
            PBLCourseTemplate.id != template.id
        ).first()
        if existing:
            return error_response(
                message=f"模板编码 {template_data.template_code} 已被其他模板使用",
                code=400,
                status_code=status.HTTP_400_BAD_REQUEST
            )
    
    # 更新字段
    update_dict = template_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(template, field, value)
    
    db.commit()
    db.refresh(template)
    
    template_result = CourseTemplate.model_validate(template).model_dump(mode='json')
    return success_response(data=template_result, message="课程模板更新成功")


@router.delete("/templates/{template_uuid}")
def delete_course_template(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程模板（仅平台管理员）"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以删除课程模板")
    
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查是否有课程在使用此模板
    courses_using_template = db.query(PBLCourse).filter(
        PBLCourse.template_id == template.id
    ).count()
    
    if courses_using_template > 0:
        return error_response(
            message=f"该模板正在被 {courses_using_template} 个课程使用，无法删除",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    db.delete(template)
    db.commit()
    
    return success_response(message="课程模板删除成功")

@router.get("/{course_uuid}")
def get_course(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程详情"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    return success_response(data=serialize_course(course))

@router.put("/{course_uuid}")
def update_course(
    course_uuid: str,
    course_data: CourseBase,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    for field, value in course_data.dict(exclude_unset=True).items():
        setattr(course, field, value)
    
    db.commit()
    db.refresh(course)
    
    return success_response(data=serialize_course(course), message="课程更新成功")

@router.delete("/{course_uuid}")
def delete_course(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(course)
    db.commit()
    
    return success_response(message="课程删除成功")

@router.get("/{course_uuid}/full-detail")
def get_course_full_detail(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程完整详情（包括所有单元、资料和任务）"""
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 序列化课程基本信息
    course_data = serialize_course(course)
    
    # 获取课程的所有单元（按顺序）
    units = db.query(PBLUnit).filter(PBLUnit.course_id == course.id).order_by(PBLUnit.order).all()
    
    units_data = []
    for unit in units:
        unit_dict = {
            'id': unit.id,
            'uuid': unit.uuid,
            'title': unit.title,
            'description': unit.description,
            'order': unit.order,
            'status': unit.status,
            'open_from': unit.open_from.isoformat() if unit.open_from else None,
            'created_at': unit.created_at.isoformat() if unit.created_at else None,
            'updated_at': unit.updated_at.isoformat() if unit.updated_at else None
        }
        
        # 获取单元的资料（按顺序）
        resources = db.query(PBLResource).filter(PBLResource.unit_id == unit.id).order_by(PBLResource.order).all()
        unit_dict['resources'] = [
            {
                'id': r.id,
                'uuid': r.uuid,
                'type': r.type,
                'title': r.title,
                'description': r.description,
                'url': r.url,
                'duration': r.duration,
                'order': r.order
            }
            for r in resources
        ]
        
        # 获取单元的任务
        tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
        unit_dict['tasks'] = [
            {
                'id': t.id,
                'uuid': t.uuid,
                'title': t.title,
                'description': t.description,
                'type': t.type,
                'difficulty': t.difficulty,
                'estimated_time': t.estimated_time
            }
            for t in tasks
        ]
        
        units_data.append(unit_dict)
    
    course_data['units'] = units_data
    
    return success_response(data=course_data)

@router.patch("/{course_uuid}/status")
def update_course_status(
    course_uuid: str,
    new_status: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程状态"""
    if new_status not in ['draft', 'published', 'archived']:
        return error_response(
            message="无效的状态值",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    course.status = new_status
    db.commit()
    db.refresh(course)
    
    return success_response(data=serialize_course(course), message="课程状态更新成功")


# ==========================================================================================================
# 课程模板资源管理 API
# ==========================================================================================================

@router.get("/templates/{template_uuid}/full-detail")
def get_template_full_detail(
    template_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程模板完整详情（包括所有单元、资源和任务）"""
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 序列化模板基本信息
    template_data = CourseTemplate.model_validate(template).model_dump(mode='json')
    
    # 获取模板的所有单元（按顺序）
    units = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.course_template_id == template.id
    ).order_by(PBLUnitTemplate.order).all()
    
    units_data = []
    for unit in units:
        unit_dict = UnitTemplate.model_validate(unit).model_dump(mode='json')
        
        # 获取单元的资源（按顺序）
        resources = db.query(PBLResourceTemplate).filter(
            PBLResourceTemplate.unit_template_id == unit.id
        ).order_by(PBLResourceTemplate.order).all()
        unit_dict['resources'] = [
            ResourceTemplate.model_validate(r).model_dump(mode='json') 
            for r in resources
        ]
        
        # 获取单元的任务（按顺序）
        tasks = db.query(PBLTaskTemplate).filter(
            PBLTaskTemplate.unit_template_id == unit.id
        ).order_by(PBLTaskTemplate.order).all()
        unit_dict['tasks'] = [
            TaskTemplate.model_validate(t).model_dump(mode='json') 
            for t in tasks
        ]
        
        units_data.append(unit_dict)
    
    template_data['units'] = units_data
    
    return success_response(data=template_data)


# ==========================================================================================================
# 单元模板管理 API
# ==========================================================================================================

@router.post("/templates/{template_uuid}/units")
def create_unit_template(
    template_uuid: str,
    unit_data: UnitTemplateCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为课程模板创建单元模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以创建单元模板")
    
    # 查找课程模板
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.uuid == template_uuid
    ).first()
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查模板编码是否已存在
    existing = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.course_template_id == template.id,
        PBLUnitTemplate.template_code == unit_data.template_code
    ).first()
    if existing:
        return error_response(
            message=f"单元模板编码 {unit_data.template_code} 已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建单元模板
    new_unit = PBLUnitTemplate(
        uuid=str(uuid_lib.uuid4()),
        course_template_id=template.id,
        template_code=unit_data.template_code,
        title=unit_data.title,
        description=unit_data.description,
        order=unit_data.order,
        learning_objectives=unit_data.learning_objectives,
        key_concepts=unit_data.key_concepts,
        estimated_duration=unit_data.estimated_duration
    )
    
    db.add(new_unit)
    db.commit()
    db.refresh(new_unit)
    
    unit_result = UnitTemplate.model_validate(new_unit).model_dump(mode='json')
    return success_response(data=unit_result, message="单元模板创建成功")


@router.put("/templates/{template_uuid}/units/{unit_uuid}")
def update_unit_template(
    template_uuid: str,
    unit_uuid: str,
    unit_data: UnitTemplateUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新单元模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以修改单元模板")
    
    unit = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.uuid == unit_uuid
    ).first()
    
    if not unit:
        return error_response(
            message="单元模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = unit_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(unit, field, value)
    
    db.commit()
    db.refresh(unit)
    
    unit_result = UnitTemplate.model_validate(unit).model_dump(mode='json')
    return success_response(data=unit_result, message="单元模板更新成功")


@router.delete("/templates/{template_uuid}/units/{unit_uuid}")
def delete_unit_template(
    template_uuid: str,
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除单元模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以删除单元模板")
    
    unit = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.uuid == unit_uuid
    ).first()
    
    if not unit:
        return error_response(
            message="单元模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(unit)
    db.commit()
    
    return success_response(message="单元模板删除成功")


# ==========================================================================================================
# 资源模板管理 API
# ==========================================================================================================

@router.post("/templates/{template_uuid}/units/{unit_uuid}/resources")
def create_resource_template(
    template_uuid: str,
    unit_uuid: str,
    resource_data: ResourceTemplateCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为单元模板创建资源模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以创建资源模板")
    
    # 查找单元模板
    unit = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.uuid == unit_uuid
    ).first()
    if not unit:
        return error_response(
            message="单元模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查模板编码是否已存在
    existing = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.unit_template_id == unit.id,
        PBLResourceTemplate.template_code == resource_data.template_code
    ).first()
    if existing:
        return error_response(
            message=f"资源模板编码 {resource_data.template_code} 已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建资源模板
    new_resource = PBLResourceTemplate(
        uuid=str(uuid_lib.uuid4()),
        unit_template_id=unit.id,
        template_code=resource_data.template_code,
        type=resource_data.type,
        title=resource_data.title,
        description=resource_data.description,
        order=resource_data.order,
        url=resource_data.url,
        content=resource_data.content,
        video_id=resource_data.video_id,
        video_cover_url=resource_data.video_cover_url,
        duration=resource_data.duration,
        default_max_views=resource_data.default_max_views,
        is_preview_allowed=resource_data.is_preview_allowed,
        meta_data=resource_data.meta_data
    )
    
    db.add(new_resource)
    db.commit()
    db.refresh(new_resource)
    
    resource_result = ResourceTemplate.model_validate(new_resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源模板创建成功")


@router.get("/templates/{template_uuid}/units/{unit_uuid}/resources/{resource_uuid}")
def get_resource_template(
    template_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取资源模板详情"""
    resource = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    resource_result = ResourceTemplate.model_validate(resource).model_dump(mode='json')
    return success_response(data=resource_result)


@router.put("/templates/{template_uuid}/units/{unit_uuid}/resources/{resource_uuid}")
def update_resource_template(
    template_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    resource_data: ResourceTemplateUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新资源模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以修改资源模板")
    
    resource = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = resource_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(resource, field, value)
    
    db.commit()
    db.refresh(resource)
    
    resource_result = ResourceTemplate.model_validate(resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源模板更新成功")


@router.delete("/templates/{template_uuid}/units/{unit_uuid}/resources/{resource_uuid}")
def delete_resource_template(
    template_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除资源模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以删除资源模板")
    
    resource = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(resource)
    db.commit()
    
    return success_response(message="资源模板删除成功")


def validate_uuid_format(uuid_string: str) -> bool:
    """验证UUID格式，防止路径遍历攻击"""
    uuid_pattern = re.compile(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', re.IGNORECASE)
    return bool(uuid_pattern.match(uuid_string))


def validate_image_content(content: bytes) -> tuple[bool, str]:
    """
    验证文件内容是否为真实的图片
    返回: (是否有效, 实际图片类型)
    """
    # 使用imghdr检测图片类型（基于文件头魔数）
    import io
    image_type = imghdr.what(None, h=content)
    
    if image_type is None:
        return False, ""
    
    # 只允许安全的图片格式
    allowed_types = {'jpeg', 'png', 'gif', 'webp'}
    return image_type in allowed_types, image_type


def validate_mime_type(content_type: str) -> bool:
    """验证MIME类型"""
    allowed_mime_types = {
        'image/jpeg',
        'image/jpg', 
        'image/png',
        'image/gif',
        'image/webp'
    }
    return content_type.lower() in allowed_mime_types


def sanitize_filename(filename: str) -> str:
    """清理文件名，移除危险字符"""
    # 只保留字母、数字、点、下划线、连字符
    return re.sub(r'[^\w\s.-]', '', filename)


@router.post("/templates/{template_uuid}/units/{unit_uuid}/resources/{resource_uuid}/upload-image")
async def upload_resource_image(
    template_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """
    上传资源文档中的图片（安全加固版）
    
    安全措施：
    1. 权限验证 - 仅平台管理员
    2. UUID格式验证 - 防止路径遍历
    3. MIME类型验证 - 检查Content-Type
    4. 文件扩展名验证 - 白名单机制
    5. 文件大小限制 - 5MB上限
    6. 魔数验证 - 检查真实文件类型
    7. 文件名清理 - 移除危险字符
    8. 唯一文件名 - 防止覆盖
    """
    
    # 1. 权限验证
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以上传图片")
    
    # 2. UUID格式验证（防止路径遍历攻击）
    if not validate_uuid_format(template_uuid):
        return error_response(
            message="无效的模板UUID格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    if not validate_uuid_format(unit_uuid):
        return error_response(
            message="无效的单元UUID格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    if not validate_uuid_format(resource_uuid):
        return error_response(
            message="无效的资源UUID格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 3. 验证资源是否存在
    resource = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 4. 验证MIME类型
    if not validate_mime_type(file.content_type):
        return error_response(
            message=f"不支持的MIME类型：{file.content_type}，仅支持图片格式",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 5. 验证文件扩展名
    allowed_extensions = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}
    original_filename = sanitize_filename(file.filename)
    file_ext = Path(original_filename).suffix.lower()
    
    if not file_ext or file_ext not in allowed_extensions:
        return error_response(
            message=f"不支持的文件扩展名，允许的格式：{', '.join(allowed_extensions)}",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 6. 读取并验证文件大小（5MB）
    content = await file.read()
    content_size = len(content)
    
    if content_size == 0:
        return error_response(
            message="文件内容为空",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    if content_size > 5 * 1024 * 1024:
        return error_response(
            message="图片大小不能超过 5MB",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 7. 验证文件内容（魔数检查）
    is_valid_image, actual_type = validate_image_content(content)
    if not is_valid_image:
        return error_response(
            message="文件不是有效的图片格式或包含恶意内容",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 8. 构建安全的存储路径
    upload_base = Path("uploads")
    
    # 确保uploads目录存在且安全
    if not upload_base.exists():
        upload_base.mkdir(mode=0o755, exist_ok=True)
    
    # 构建完整路径，使用验证过的UUID
    upload_dir = upload_base / "course-templates" / template_uuid / "resources" / resource_uuid / "images"
    
    # 创建目录时设置安全权限
    upload_dir.mkdir(parents=True, mode=0o755, exist_ok=True)
    
    # 9. 生成唯一且安全的文件名
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    unique_id = uuid_lib.uuid4().hex[:8]
    
    # 使用实际检测到的图片类型作为扩展名
    if actual_type == 'jpeg':
        safe_ext = '.jpg'
    else:
        safe_ext = f'.{actual_type}'
    
    unique_filename = f"{timestamp}_{unique_id}{safe_ext}"
    file_path = upload_dir / unique_filename
    
    # 10. 确保文件不存在（双重保险）
    if file_path.exists():
        return error_response(
            message="文件名冲突，请重试",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
    
    # 11. 保存文件
    try:
        # 使用安全的文件权限（只读）
        with open(file_path, "wb") as buffer:
            buffer.write(content)
        
        # 设置文件权限（只读）
        os.chmod(file_path, 0o644)
        
        # 构建访问URL（相对路径）
        file_url = f"/uploads/course-templates/{template_uuid}/resources/{resource_uuid}/images/{unique_filename}"
        
        return success_response(
            data={
                "filename": original_filename,
                "url": file_url,
                "size": content_size,
                "type": actual_type,
                "uploaded_at": datetime.now().isoformat()
            },
            message="图片上传成功"
        )
    except Exception as e:
        # 如果保存失败，尝试删除已创建的文件
        if file_path.exists():
            try:
                file_path.unlink()
            except:
                pass
        
        return error_response(
            message=f"图片保存失败：{str(e)}",
            code=500,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ==========================================================================================================
# 任务模板管理 API
# ==========================================================================================================

@router.post("/templates/{template_uuid}/units/{unit_uuid}/tasks")
def create_task_template(
    template_uuid: str,
    unit_uuid: str,
    task_data: TaskTemplateCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为单元模板创建任务模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以创建任务模板")
    
    # 查找单元模板
    unit = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.uuid == unit_uuid
    ).first()
    if not unit:
        return error_response(
            message="单元模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查模板编码是否已存在
    existing = db.query(PBLTaskTemplate).filter(
        PBLTaskTemplate.unit_template_id == unit.id,
        PBLTaskTemplate.template_code == task_data.template_code
    ).first()
    if existing:
        return error_response(
            message=f"任务模板编码 {task_data.template_code} 已存在",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 创建任务模板
    new_task = PBLTaskTemplate(
        uuid=str(uuid_lib.uuid4()),
        unit_template_id=unit.id,
        template_code=task_data.template_code,
        title=task_data.title,
        description=task_data.description,
        type=task_data.type,
        difficulty=task_data.difficulty,
        order=task_data.order,
        requirements=task_data.requirements,
        deliverables=task_data.deliverables,
        evaluation_criteria=task_data.evaluation_criteria,
        estimated_time=task_data.estimated_time,
        estimated_hours=task_data.estimated_hours,
        prerequisites=task_data.prerequisites,
        required_resources=task_data.required_resources,
        hints=task_data.hints,
        reference_materials=task_data.reference_materials,
        meta_data=task_data.meta_data
    )
    
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    
    task_result = TaskTemplate.model_validate(new_task).model_dump(mode='json')
    return success_response(data=task_result, message="任务模板创建成功")


@router.put("/templates/{template_uuid}/units/{unit_uuid}/tasks/{task_uuid}")
def update_task_template(
    template_uuid: str,
    unit_uuid: str,
    task_uuid: str,
    task_data: TaskTemplateUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新任务模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以修改任务模板")
    
    task = db.query(PBLTaskTemplate).filter(
        PBLTaskTemplate.uuid == task_uuid
    ).first()
    
    if not task:
        return error_response(
            message="任务模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = task_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    
    task_result = TaskTemplate.model_validate(task).model_dump(mode='json')
    return success_response(data=task_result, message="任务模板更新成功")


@router.delete("/templates/{template_uuid}/units/{unit_uuid}/tasks/{task_uuid}")
def delete_task_template(
    template_uuid: str,
    unit_uuid: str,
    task_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除任务模板"""
    # 检查权限
    if current_admin.role != 'platform_admin':
        raise HTTPException(status_code=403, detail="仅平台管理员可以删除任务模板")
    
    task = db.query(PBLTaskTemplate).filter(
        PBLTaskTemplate.uuid == task_uuid
    ).first()
    
    if not task:
        return error_response(
            message="任务模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(task)
    db.commit()
    
    return success_response(message="任务模板删除成功")


# ==========================================================================================================
# 课程单元管理 API
# ==========================================================================================================

@router.post("/{course_uuid}/units")
def create_course_unit(
    course_uuid: str,
    unit_data: UnitCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为课程创建单元"""
    # 查找课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 创建单元
    new_unit = PBLUnit(
        uuid=str(uuid_lib.uuid4()),
        course_id=course.id,
        title=unit_data.title,
        description=unit_data.description,
        order=unit_data.order or 0,
        status=unit_data.status or 'locked',
        learning_guide=unit_data.learning_guide
    )
    
    db.add(new_unit)
    db.commit()
    db.refresh(new_unit)
    
    unit_result = Unit.model_validate(new_unit).model_dump(mode='json')
    return success_response(data=unit_result, message="单元创建成功")


@router.put("/{course_uuid}/units/{unit_uuid}")
def update_course_unit(
    course_uuid: str,
    unit_uuid: str,
    unit_data: UnitUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新课程单元"""
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = unit_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(unit, field, value)
    
    db.commit()
    db.refresh(unit)
    
    unit_result = Unit.model_validate(unit).model_dump(mode='json')
    return success_response(data=unit_result, message="单元更新成功")


@router.delete("/{course_uuid}/units/{unit_uuid}")
def delete_course_unit(
    course_uuid: str,
    unit_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除课程单元"""
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 删除单元相关的资源和任务
    db.query(PBLResource).filter(PBLResource.unit_id == unit.id).delete()
    db.query(PBLTask).filter(PBLTask.unit_id == unit.id).delete()
    
    db.delete(unit)
    db.commit()
    
    return success_response(message="单元删除成功")


# ==========================================================================================================
# 课程资源管理 API
# ==========================================================================================================

@router.post("/{course_uuid}/units/{unit_uuid}/resources")
def create_course_resource(
    course_uuid: str,
    unit_uuid: str,
    resource_data: ResourceCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为单元创建资源"""
    # 查找单元
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 创建资源
    new_resource = PBLResource(
        uuid=str(uuid_lib.uuid4()),
        unit_id=unit.id,
        type=resource_data.type,
        title=resource_data.title,
        description=resource_data.description,
        url=resource_data.url,
        content=resource_data.content,
        duration=resource_data.duration,
        order=resource_data.order or 0,
        video_id=resource_data.video_id,
        video_cover_url=resource_data.video_cover_url
    )
    
    db.add(new_resource)
    db.commit()
    db.refresh(new_resource)
    
    resource_result = Resource.model_validate(new_resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源创建成功")


@router.put("/{course_uuid}/units/{unit_uuid}/resources/{resource_uuid}")
def update_course_resource(
    course_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    resource_data: ResourceUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新资源"""
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = resource_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(resource, field, value)
    
    db.commit()
    db.refresh(resource)
    
    resource_result = Resource.model_validate(resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源更新成功")


@router.delete("/{course_uuid}/units/{unit_uuid}/resources/{resource_uuid}")
def delete_course_resource(
    course_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除资源"""
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(resource)
    db.commit()
    
    return success_response(message="资源删除成功")


@router.patch("/{course_uuid}/units/{unit_uuid}/resources/{resource_uuid}/order")
def update_resource_order(
    course_uuid: str,
    unit_uuid: str,
    resource_uuid: str,
    new_order: int = Query(..., description="新的顺序值"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新资源顺序"""
    resource = db.query(PBLResource).filter(
        PBLResource.uuid == resource_uuid
    ).first()
    
    if not resource:
        return error_response(
            message="资源不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    old_order = resource.order
    resource.order = new_order
    
    # 更新其他资源的顺序
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if unit:
        if new_order < old_order:
            # 上移：将中间的资源顺序+1
            db.query(PBLResource).filter(
                PBLResource.unit_id == unit.id,
                PBLResource.order >= new_order,
                PBLResource.order < old_order,
                PBLResource.id != resource.id
            ).update({PBLResource.order: PBLResource.order + 1}, synchronize_session=False)
        elif new_order > old_order:
            # 下移：将中间的资源顺序-1
            db.query(PBLResource).filter(
                PBLResource.unit_id == unit.id,
                PBLResource.order > old_order,
                PBLResource.order <= new_order,
                PBLResource.id != resource.id
            ).update({PBLResource.order: PBLResource.order - 1}, synchronize_session=False)
    
    db.commit()
    db.refresh(resource)
    
    resource_result = Resource.model_validate(resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源顺序更新成功")


# ==========================================================================================================
# 课程任务管理 API
# ==========================================================================================================

@router.post("/{course_uuid}/units/{unit_uuid}/tasks")
def create_course_task(
    course_uuid: str,
    unit_uuid: str,
    task_data: TaskCreate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """为单元创建任务"""
    # 查找单元
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 创建任务
    new_task = PBLTask(
        uuid=str(uuid_lib.uuid4()),
        unit_id=unit.id,
        title=task_data.title,
        description=task_data.description,
        type=task_data.type or 'analysis',
        difficulty=task_data.difficulty or 'easy',
        estimated_time=task_data.estimated_time,
        order=task_data.order or 0,
        requirements=task_data.requirements,
        prerequisites=task_data.prerequisites
    )
    
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    
    task_result = Task.model_validate(new_task).model_dump(mode='json')
    return success_response(data=task_result, message="任务创建成功")


@router.put("/{course_uuid}/units/{unit_uuid}/tasks/{task_uuid}")
def update_course_task(
    course_uuid: str,
    unit_uuid: str,
    task_uuid: str,
    task_data: TaskUpdate,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """更新任务"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 更新字段
    update_dict = task_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(task, field, value)
    
    db.commit()
    db.refresh(task)
    
    task_result = Task.model_validate(task).model_dump(mode='json')
    return success_response(data=task_result, message="任务更新成功")


@router.delete("/{course_uuid}/units/{unit_uuid}/tasks/{task_uuid}")
def delete_course_task(
    course_uuid: str,
    unit_uuid: str,
    task_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """删除任务"""
    task = db.query(PBLTask).filter(PBLTask.uuid == task_uuid).first()
    
    if not task:
        return error_response(
            message="任务不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    db.delete(task)
    db.commit()
    
    return success_response(message="任务删除成功")


# ==========================================================================================================
# 从模板选择资源和任务 API
# ==========================================================================================================

@router.get("/{course_uuid}/template-resources")
def get_course_template_resources(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程所对应模板的所有资源"""
    # 查找课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查课程是否关联模板
    if not course.template_id:
        return error_response(
            message="该课程未关联课程模板",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 查找模板
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.id == course.template_id
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取模板的所有单元
    units = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.course_template_id == template.id
    ).order_by(PBLUnitTemplate.order).all()
    
    # 构建资源列表（包含单元信息）
    resources_data = []
    for unit in units:
        resources = db.query(PBLResourceTemplate).filter(
            PBLResourceTemplate.unit_template_id == unit.id
        ).order_by(PBLResourceTemplate.order).all()
        
        for resource in resources:
            resource_dict = ResourceTemplate.model_validate(resource).model_dump(mode='json')
            resource_dict['unit_name'] = unit.title  # 添加单元名称
            resource_dict['unit_uuid'] = unit.uuid
            resources_data.append(resource_dict)
    
    return success_response(data={
        "template_title": template.title,
        "template_uuid": template.uuid,
        "resources": resources_data
    })


@router.get("/{course_uuid}/template-tasks")
def get_course_template_tasks(
    course_uuid: str,
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """获取课程所对应模板的所有任务"""
    # 查找课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 检查课程是否关联模板
    if not course.template_id:
        return error_response(
            message="该课程未关联课程模板",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 查找模板
    template = db.query(PBLCourseTemplate).filter(
        PBLCourseTemplate.id == course.template_id
    ).first()
    
    if not template:
        return error_response(
            message="课程模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取模板的所有单元
    units = db.query(PBLUnitTemplate).filter(
        PBLUnitTemplate.course_template_id == template.id
    ).order_by(PBLUnitTemplate.order).all()
    
    # 构建任务列表（包含单元信息）
    tasks_data = []
    for unit in units:
        tasks = db.query(PBLTaskTemplate).filter(
            PBLTaskTemplate.unit_template_id == unit.id
        ).order_by(PBLTaskTemplate.order).all()
        
        for task in tasks:
            task_dict = TaskTemplate.model_validate(task).model_dump(mode='json')
            task_dict['unit_name'] = unit.title  # 添加单元名称
            task_dict['unit_uuid'] = unit.uuid
            tasks_data.append(task_dict)
    
    return success_response(data={
        "template_title": template.title,
        "template_uuid": template.uuid,
        "tasks": tasks_data
    })


@router.post("/{course_uuid}/units/{unit_uuid}/resources/copy-from-template")
def copy_resource_from_template(
    course_uuid: str,
    unit_uuid: str,
    resource_template_uuid: str = Query(..., description="资源模板UUID"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从模板复制资源到课程单元"""
    # 查找目标单元
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找资源模板
    resource_template = db.query(PBLResourceTemplate).filter(
        PBLResourceTemplate.uuid == resource_template_uuid
    ).first()
    
    if not resource_template:
        return error_response(
            message="资源模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取当前单元的最大order值
    max_order = db.query(PBLResource).filter(
        PBLResource.unit_id == unit.id
    ).count()
    
    # 复制资源
    new_resource = PBLResource(
        uuid=str(uuid_lib.uuid4()),
        unit_id=unit.id,
        type=resource_template.type,
        title=resource_template.title,
        description=resource_template.description,
        url=resource_template.url,
        content=resource_template.content,
        duration=resource_template.duration,
        order=max_order + 1,
        video_id=resource_template.video_id,
        video_cover_url=resource_template.video_cover_url,
        max_views=resource_template.default_max_views  # 使用模板的默认值
    )
    
    db.add(new_resource)
    db.commit()
    db.refresh(new_resource)
    
    resource_result = Resource.model_validate(new_resource).model_dump(mode='json')
    return success_response(data=resource_result, message="资源复制成功")


@router.post("/{course_uuid}/units/{unit_uuid}/tasks/copy-from-template")
def copy_task_from_template(
    course_uuid: str,
    unit_uuid: str,
    task_template_uuid: str = Query(..., description="任务模板UUID"),
    db: Session = Depends(get_db),
    current_admin: Admin = Depends(get_current_admin)
):
    """从模板复制任务到课程单元"""
    # 查找目标单元
    unit = db.query(PBLUnit).filter(PBLUnit.uuid == unit_uuid).first()
    if not unit:
        return error_response(
            message="单元不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 查找任务模板
    task_template = db.query(PBLTaskTemplate).filter(
        PBLTaskTemplate.uuid == task_template_uuid
    ).first()
    
    if not task_template:
        return error_response(
            message="任务模板不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取当前单元的最大order值
    max_order = db.query(PBLTask).filter(
        PBLTask.unit_id == unit.id
    ).count()
    
    # 复制任务
    new_task = PBLTask(
        uuid=str(uuid_lib.uuid4()),
        unit_id=unit.id,
        title=task_template.title,
        description=task_template.description,
        type=task_template.type,
        difficulty=task_template.difficulty,
        order=max_order + 1,
        requirements=task_template.requirements,
        estimated_time=task_template.estimated_time,
        prerequisites=task_template.prerequisites
    )
    
    db.add(new_task)
    db.commit()
    db.refresh(new_task)
    
    task_result = Task.model_validate(new_task).model_dump(mode='json')
    return success_response(data=task_result, message="任务复制成功")
