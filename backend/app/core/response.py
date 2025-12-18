"""
统一响应格式
提供标准的 API 响应格式，包含 code、message、data 字段
"""
from typing import Any, Optional, Generic, TypeVar
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse
from fastapi import status as http_status

T = TypeVar('T')

class StandardResponse(BaseModel, Generic[T]):
    """标准响应格式"""
    code: int = Field(..., description="状态码，200表示成功，其他值表示失败")
    message: str = Field(..., description="响应消息")
    data: Optional[T] = Field(None, description="响应数据")

    class Config:
        json_schema_extra = {
            "example": {
                "code": 200,
                "message": "操作成功",
                "data": {}
            }
        }


class ErrorResponse(BaseModel):
    """错误响应格式"""
    code: int = Field(..., description="错误状态码")
    message: str = Field(..., description="错误消息")
    detail: Optional[str] = Field(None, description="错误详情")

    class Config:
        json_schema_extra = {
            "example": {
                "code": 400,
                "message": "请求参数错误",
                "detail": "具体错误信息"
            }
        }


def success_response(data: Any = None, message: str = "操作成功") -> dict:
    """创建成功响应"""
    return {
        "code": 200,
        "message": message,
        "data": data
    }


def error_response(
    message: str = "操作失败",
    code: int = 400,
    detail: Optional[str] = None,
    status_code: Optional[int] = None
) -> JSONResponse:
    """创建错误响应
    
    Args:
        message: 错误消息
        code: 业务错误码（用于前端判断）
        detail: 错误详情（可选）
        status_code: HTTP状态码（可选，如果不提供则使用 code 作为HTTP状态码）
    
    Returns:
        JSONResponse: FastAPI JSONResponse对象，包含正确的HTTP状态码
    """
    response_data = {
        "code": code,
        "message": message,
    }
    if detail is not None:
        response_data["detail"] = detail
    
    # 如果没有指定HTTP状态码，使用业务code作为HTTP状态码
    # 这样可以确保401错误能被前端正确捕获
    http_code = status_code if status_code is not None else code
    
    return JSONResponse(
        status_code=http_code,
        content=response_data
    )


def error_response_dict(
    message: str = "操作失败",
    code: int = 400,
    detail: Optional[str] = None
) -> dict:
    """创建错误响应数据字典（用于异常处理器）
    
    Args:
        message: 错误消息
        code: 业务错误码（用于前端判断）
        detail: 错误详情（可选）
    
    Returns:
        dict: 错误响应数据字典
    """
    response_data = {
        "code": code,
        "message": message,
    }
    if detail is not None:
        response_data["detail"] = detail
    
    return response_data

