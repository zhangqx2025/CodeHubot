"""
结束节点执行器
收集执行结果，作为工作流的出口
"""
import logging
import json
from typing import Dict, Any, Callable

logger = logging.getLogger(__name__)


async def execute_end_node(
    node_data: Dict[str, Any],
    execution_context: Dict[str, Any],
    replace_variables: Callable[[str], str]
) -> Dict[str, Any]:
    """
    执行结束节点
    
    Args:
        node_data: 节点配置数据
        execution_context: 执行上下文
        replace_variables: 变量替换函数
        
    Returns:
        Dict[str, Any]: 节点输出
    """
    output_content = node_data.get("outputContent")
    
    # 优先使用 outputContent (这是前端直接编辑的字段)
    if output_content:
        # 执行变量替换
        final_content = replace_variables(output_content)
        logger.info(f"结束节点输出(自定义): {final_content}")
        
        # 尝试判断是否是JSON格式，如果是则解析，否则返回字符串
        try:
            if (final_content.startswith("{") and final_content.endswith("}")) or \
               (final_content.startswith("[") and final_content.endswith("]")):
                return json.loads(final_content)
        except:
            pass
            
        return {"output": final_content}
        
    # 默认逻辑：收集所有节点输出（排除input）
    output = {
        node_id: output 
        for node_id, output in execution_context.items() 
        if node_id != "input"
    }
    logger.info(f"结束节点输出(默认): {output}")
    return output
