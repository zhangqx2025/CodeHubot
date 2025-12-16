from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Tuple

from ...core.response import success_response, error_response
from ...core.deps import get_db, get_current_channel_partner
from ...core.logging_config import get_logger
from ...models.admin import Admin, User
from ...models.pbl import (
    PBLCourse, PBLClass, PBLClassMember, PBLClassTeacher,
    PBLGroup, PBLGroupMember, PBLUnit, PBLTask, PBLTaskProgress,
    ChannelSchoolRelation
)
from ...models.school import School
from ...utils.timezone import get_beijing_time_naive

router = APIRouter()
logger = get_logger(__name__)

# ===== 辅助函数 =====

def verify_channel_school_permission(
    school_id: int,
    channel_partner_id: int,
    db: Session
) -> Tuple[School, ChannelSchoolRelation]:
    """
    验证渠道商是否有权限访问该学校
    
    Args:
        school_id: 学校ID
        channel_partner_id: 渠道商ID
        db: 数据库会话
    
    Returns:
        (学校对象, 渠道商学校关联对象)
    
    Raises:
        HTTPException: 权限验证失败时抛出
    """
    # 查询学校
    school = db.query(School).filter(School.id == school_id).first()
    if not school:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="学校不存在"
        )
    
    # 验证渠道商是否负责该学校
    relation = db.query(ChannelSchoolRelation).filter(
        ChannelSchoolRelation.channel_partner_id == channel_partner_id,
        ChannelSchoolRelation.school_id == school_id,
        ChannelSchoolRelation.is_active == 1
    ).first()
    
    if not relation:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权限访问该学校"
        )
    
    return school, relation

# ===== 学校管理 =====

@router.get("/schools")
def get_channel_schools(
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取渠道商负责的所有学校列表"""
    logger.info(f"渠道商 {current_channel.username} (ID: {current_channel.id}) 查询学校列表")
    
    # 查询渠道商负责的学校关联
    relations = db.query(ChannelSchoolRelation).filter(
        ChannelSchoolRelation.channel_partner_id == current_channel.id,
        ChannelSchoolRelation.is_active == 1
    ).all()
    
    if not relations:
        return success_response(data=[], message="暂无负责的学校")
    
    school_ids = [rel.school_id for rel in relations]
    
    # 查询学校详情
    schools = db.query(School).filter(
        School.id.in_(school_ids)
    ).all()
    
    result = []
    for school in schools:
        # 统计班级数量
        class_count = db.query(func.count(PBLClass.id)).filter(
            PBLClass.school_id == school.id
        ).scalar()
        
        # 统计课程数量（通过班级关联）
        course_count = db.query(func.count(PBLCourse.id)).join(
            PBLClass, PBLCourse.class_id == PBLClass.id
        ).filter(
            PBLClass.school_id == school.id
        ).scalar()
        
        # 统计教师数量
        teacher_count = db.query(func.count(User.id)).filter(
            User.school_id == school.id,
            User.role == 'teacher'
        ).scalar()
        
        # 统计学生数量
        student_count = db.query(func.count(User.id)).filter(
            User.school_id == school.id,
            User.role == 'student'
        ).scalar()
        
        result.append({
            "id": school.id,
            "uuid": school.uuid,
            "school_code": school.school_code,
            "school_name": school.school_name,
            "province": school.province,
            "city": school.city,
            "district": school.district,
            "is_active": school.is_active,
            "statistics": {
                "class_count": class_count,
                "course_count": course_count,
                "teacher_count": teacher_count,
                "student_count": student_count
            },
            "created_at": school.created_at.isoformat() if school.created_at else None
        })
    
    logger.info(f"渠道商 {current_channel.username} 共负责 {len(result)} 所学校")
    return success_response(data=result)

@router.get("/schools/{school_id}")
def get_school_detail(
    school_id: int,
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取学校详细信息"""
    logger.info(f"渠道商 {current_channel.username} 查询学校详情: school_id={school_id}")
    
    # 验证权限
    try:
        school, relation = verify_channel_school_permission(school_id, current_channel.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 获取班级列表
    classes = db.query(PBLClass).filter(
        PBLClass.school_id == school_id
    ).all()
    
    class_list = []
    for pbl_class in classes:
        # 统计课程数量
        course_count = db.query(func.count(PBLCourse.id)).filter(
            PBLCourse.class_id == pbl_class.id
        ).scalar()
        
        class_list.append({
            "id": pbl_class.id,
            "uuid": pbl_class.uuid,
            "name": pbl_class.name,
            "class_type": pbl_class.class_type,
            "current_members": pbl_class.current_members,
            "course_count": course_count,
            "is_active": pbl_class.is_active
        })
    
    # 获取统计数据
    teacher_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'teacher'
    ).scalar()
    
    student_count = db.query(func.count(User.id)).filter(
        User.school_id == school_id,
        User.role == 'student'
    ).scalar()
    
    result = {
        "id": school.id,
        "uuid": school.uuid,
        "school_code": school.school_code,
        "school_name": school.school_name,
        "province": school.province,
        "city": school.city,
        "district": school.district,
        "address": school.address,
        "contact_person": school.contact_person,
        "contact_phone": school.contact_phone,
        "contact_email": school.contact_email,
        "is_active": school.is_active,
        "description": school.description,
        "classes": class_list,
        "statistics": {
            "class_count": len(class_list),
            "teacher_count": teacher_count,
            "student_count": student_count
        },
        "created_at": school.created_at.isoformat() if school.created_at else None
    }
    
    return success_response(data=result)

@router.get("/schools/{school_id}/courses")
def get_school_courses(
    school_id: int,
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取学校的所有课程列表"""
    logger.info(f"渠道商 {current_channel.username} 查询学校课程: school_id={school_id}")
    
    # 验证权限
    try:
        school, relation = verify_channel_school_permission(school_id, current_channel.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 查询学校的所有班级
    classes = db.query(PBLClass).filter(
        PBLClass.school_id == school_id
    ).all()
    
    if not classes:
        return success_response(data=[], message="该学校暂无班级")
    
    class_ids = [c.id for c in classes]
    
    # 查询这些班级的课程
    courses = db.query(PBLCourse).filter(
        PBLCourse.class_id.in_(class_ids)
    ).all()
    
    result = []
    for course in courses:
        # 获取班级信息
        pbl_class = next((c for c in classes if c.id == course.class_id), None)
        
        # 统计单元数量
        unit_count = db.query(func.count(PBLUnit.id)).filter(
            PBLUnit.course_id == course.id
        ).scalar()
        
        # 统计任务数量
        task_count = db.query(func.count(PBLTask.id)).join(
            PBLUnit, PBLTask.unit_id == PBLUnit.id
        ).filter(
            PBLUnit.course_id == course.id
        ).scalar()
        
        result.append({
            "id": course.id,
            "uuid": course.uuid,
            "title": course.title,
            "description": course.description,
            "cover_image": course.cover_image,
            "difficulty": course.difficulty,
            "status": course.status,
            "class": {
                "id": pbl_class.id if pbl_class else None,
                "name": pbl_class.name if pbl_class else None,
                "current_members": pbl_class.current_members if pbl_class else 0
            },
            "statistics": {
                "unit_count": unit_count,
                "task_count": task_count
            },
            "created_at": course.created_at.isoformat() if course.created_at else None
        })
    
    return success_response(data=result)

@router.get("/courses/{course_uuid}")
def get_course_detail(
    course_uuid: str,
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取课程详细信息（只读）"""
    logger.info(f"渠道商 {current_channel.username} 查询课程详情: {course_uuid}")
    
    # 查询课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(
            message="课程不存在",
            code=404,
            status_code=status.HTTP_404_NOT_FOUND
        )
    
    # 获取班级信息
    pbl_class = None
    if course.class_id:
        pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
    
    if not pbl_class:
        return error_response(
            message="课程未关联班级",
            code=400,
            status_code=status.HTTP_400_BAD_REQUEST
        )
    
    # 验证渠道商是否负责该学校
    try:
        school, relation = verify_channel_school_permission(pbl_class.school_id, current_channel.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 获取班级成员
    member_count = db.query(func.count(PBLClassMember.id)).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).scalar()
    
    # 获取小组信息
    group_count = db.query(func.count(PBLGroup.id)).filter(
        PBLGroup.class_id == pbl_class.id,
        PBLGroup.is_active == 1
    ).scalar()
    
    # 获取教师信息
    teachers = db.query(PBLClassTeacher, User).join(
        User, PBLClassTeacher.teacher_id == User.id
    ).filter(
        PBLClassTeacher.class_id == pbl_class.id
    ).all()
    
    teacher_list = []
    for teacher_rel, user in teachers:
        teacher_list.append({
            "id": user.id,
            "name": user.name or user.real_name,
            "teacher_number": user.teacher_number,
            "role": teacher_rel.role,
            "subject": teacher_rel.subject,
            "is_primary": teacher_rel.is_primary
        })
    
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
            "task_count": task_count
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
        "class": {
            "id": pbl_class.id,
            "uuid": pbl_class.uuid,
            "name": pbl_class.name,
            "class_type": pbl_class.class_type,
            "current_members": pbl_class.current_members,
            "member_count": member_count,
            "group_count": group_count
        },
        "teachers": teacher_list,
        "units": unit_list,
        "created_at": course.created_at.isoformat() if course.created_at else None
    }
    
    return success_response(data=result)

@router.get("/courses/{course_uuid}/progress")
def get_course_progress(
    course_uuid: str,
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取课程学习进度统计（只读）"""
    logger.info(f"渠道商 {current_channel.username} 查询课程进度: {course_uuid}")
    
    # 查询课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 获取班级信息
    if not course.class_id:
        return error_response(message="课程未关联班级", code=400, status_code=status.HTTP_400_BAD_REQUEST)
    
    pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
    if not pbl_class:
        return error_response(message="班级不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 验证权限
    try:
        school, relation = verify_channel_school_permission(pbl_class.school_id, current_channel.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 获取班级成员
    students = db.query(User).join(
        PBLClassMember, User.id == PBLClassMember.student_id
    ).filter(
        PBLClassMember.class_id == pbl_class.id,
        PBLClassMember.is_active == 1
    ).all()
    
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
            unit_tasks = db.query(PBLTask).filter(PBLTask.unit_id == unit.id).all()
            total_tasks += len(unit_tasks)
            
            for task in unit_tasks:
                progress = db.query(PBLTaskProgress).filter(
                    PBLTaskProgress.task_id == task.id,
                    PBLTaskProgress.user_id == student.id,
                    PBLTaskProgress.status == 'completed'
                ).first()
                
                if progress:
                    completed_tasks += 1
            
            # 判断单元是否完成
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
    
    # 整体统计
    overall_stats = {
        "total_students": len(students),
        "total_units": len(units),
        "average_progress": round(sum([s['progress_percentage'] for s in student_progress]) / len(student_progress), 2) if student_progress else 0
    }
    
    return success_response(data={
        "overall": overall_stats,
        "students": student_progress
    })

@router.get("/courses/{course_uuid}/homework")
def get_course_homework(
    course_uuid: str,
    current_channel: Admin = Depends(get_current_channel_partner),
    db: Session = Depends(get_db)
):
    """获取课程作业统计（只读）"""
    logger.info(f"渠道商 {current_channel.username} 查询课程作业: {course_uuid}")
    
    # 查询课程
    course = db.query(PBLCourse).filter(PBLCourse.uuid == course_uuid).first()
    if not course:
        return error_response(message="课程不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 获取班级信息
    if not course.class_id:
        return error_response(message="课程未关联班级", code=400, status_code=status.HTTP_400_BAD_REQUEST)
    
    pbl_class = db.query(PBLClass).filter(PBLClass.id == course.class_id).first()
    if not pbl_class:
        return error_response(message="班级不存在", code=404, status_code=status.HTTP_404_NOT_FOUND)
    
    # 验证权限
    try:
        school, relation = verify_channel_school_permission(pbl_class.school_id, current_channel.id, db)
    except HTTPException as e:
        return error_response(message=e.detail, code=e.status_code, status_code=e.status_code)
    
    # 查询任务
    tasks = db.query(PBLTask, PBLUnit).join(
        PBLUnit, PBLTask.unit_id == PBLUnit.id
    ).filter(
        PBLUnit.course_id == course.id
    ).order_by(PBLUnit.order, PBLTask.order).all()
    
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
        
        # 平均分数
        avg_score = db.query(func.avg(PBLTaskProgress.score)).filter(
            PBLTaskProgress.task_id == task.id,
            PBLTaskProgress.score.isnot(None)
        ).scalar()
        
        result.append({
            "task_id": task.id,
            "task_uuid": task.uuid,
            "task_title": task.title,
            "task_type": task.type,
            "difficulty": task.difficulty,
            "deadline": task.deadline.isoformat() if task.deadline else None,
            "unit_title": unit.title,
            "statistics": {
                "total_submissions": total_submissions,
                "pending_review": pending_review,
                "graded": graded,
                "average_score": round(float(avg_score), 2) if avg_score else None
            }
        })
    
    return success_response(data=result)
