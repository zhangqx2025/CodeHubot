"""
文档解析器
支持TXT和Markdown格式的文档解析和文本切分
"""
from typing import List, Dict, Any, Optional, Tuple
import re
import chardet


class DocumentParser:
    """文档解析器基类"""
    
    def __init__(self, chunk_size: int = 500, chunk_overlap: int = 50):
        """
        Args:
            chunk_size: 文本块大小（字符数）
            chunk_overlap: 文本块重叠大小（字符数）
        """
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
    
    def parse(self, content: bytes) -> str:
        """
        解析文档内容
        
        Args:
            content: 文档内容（bytes）
        
        Returns:
            str: 解析后的文本
        """
        raise NotImplementedError
    
    def split_into_chunks(self, text: str, mode: str = 'fixed') -> List[Dict[str, Any]]:
        """
        将文本切分为文本块
        
        Args:
            text: 文本内容
            mode: 切分模式 ('fixed'|'paragraph'|'sentence'|'custom')
        
        Returns:
            List[Dict]: 文本块列表，每个块包含content、index、char_count等
        """
        if not text or not text.strip():
            return []
        
        if mode == 'paragraph':
            return self._split_by_paragraph(text)
        elif mode == 'sentence':
            return self._split_by_sentence(text)
        else:  # fixed 或 custom
            return self._split_by_fixed_size(text)
    
    def _split_by_fixed_size(self, text: str) -> List[Dict[str, Any]]:
        """按固定大小切分"""
        chunks = []
        chunk_index = 0
        start = 0
        text_length = len(text)
        
        while start < text_length:
            # 确定当前块的结束位置
            end = start + self.chunk_size
            
            # 如果不是最后一块，尝试在句子边界处切分
            if end < text_length:
                # 尝试在句号、问号、叹号等位置切分
                sentence_end = max(
                    text.rfind('。', start, end),
                    text.rfind('？', start, end),
                    text.rfind('！', start, end),
                    text.rfind('\n\n', start, end),
                    text.rfind('\n', start, end)
                )
                
                if sentence_end > start:
                    end = sentence_end + 1
            else:
                end = text_length
            
            # 提取文本块
            chunk_text = text[start:end].strip()
            
            if chunk_text:
                chunks.append({
                    'content': chunk_text,
                    'chunk_index': chunk_index,
                    'char_count': len(chunk_text),
                    'token_count': self.estimate_token_count(chunk_text),
                    'metadata': {
                        'start_position': start,
                        'end_position': end,
                        'split_mode': 'fixed'
                    }
                })
                chunk_index += 1
            
            # 移动到下一个块的起始位置（考虑重叠）
            start = end - self.chunk_overlap
            
            # 避免死循环
            if start <= end - self.chunk_size:
                start = end
        
        return chunks
    
    def _split_by_paragraph(self, text: str) -> List[Dict[str, Any]]:
        """按段落切分"""
        # 按双换行符分割段落
        paragraphs = re.split(r'\n\n+', text)
        chunks = []
        chunk_index = 0
        current_chunk = ""
        start_pos = 0
        
        for para in paragraphs:
            para = para.strip()
            if not para:
                continue
            
            # 如果当前块加上新段落不超过块大小，合并
            if len(current_chunk) + len(para) + 2 < self.chunk_size:
                if current_chunk:
                    current_chunk += "\n\n" + para
                else:
                    current_chunk = para
            else:
                # 保存当前块
                if current_chunk:
                    chunks.append({
                        'content': current_chunk,
                        'chunk_index': chunk_index,
                        'char_count': len(current_chunk),
                        'token_count': self.estimate_token_count(current_chunk),
                        'metadata': {
                            'start_position': start_pos,
                            'end_position': start_pos + len(current_chunk),
                            'split_mode': 'paragraph'
                        }
                    })
                    chunk_index += 1
                    start_pos += len(current_chunk) + 2
                
                # 如果段落本身太长，按固定大小切分
                if len(para) > self.chunk_size:
                    sub_chunks = self._split_long_paragraph(para, chunk_index, start_pos)
                    chunks.extend(sub_chunks)
                    chunk_index += len(sub_chunks)
                    start_pos += len(para) + 2
                    current_chunk = ""
                else:
                    current_chunk = para
        
        # 保存最后一块
        if current_chunk:
            chunks.append({
                'content': current_chunk,
                'chunk_index': chunk_index,
                'char_count': len(current_chunk),
                'token_count': self.estimate_token_count(current_chunk),
                'metadata': {
                    'start_position': start_pos,
                    'end_position': start_pos + len(current_chunk),
                    'split_mode': 'paragraph'
                }
            })
        
        return chunks
    
    def _split_by_sentence(self, text: str) -> List[Dict[str, Any]]:
        """按句子切分"""
        # 按句号、问号、叹号分割句子
        sentences = re.split(r'([。？！；])', text)
        
        # 重新组合句子和标点
        combined_sentences = []
        for i in range(0, len(sentences) - 1, 2):
            if i + 1 < len(sentences):
                combined_sentences.append(sentences[i] + sentences[i + 1])
            else:
                combined_sentences.append(sentences[i])
        
        chunks = []
        chunk_index = 0
        current_chunk = ""
        start_pos = 0
        
        for sentence in combined_sentences:
            sentence = sentence.strip()
            if not sentence:
                continue
            
            # 如果当前块加上新句子不超过块大小，合并
            if len(current_chunk) + len(sentence) < self.chunk_size:
                current_chunk += sentence
            else:
                # 保存当前块
                if current_chunk:
                    chunks.append({
                        'content': current_chunk,
                        'chunk_index': chunk_index,
                        'char_count': len(current_chunk),
                        'token_count': self.estimate_token_count(current_chunk),
                        'metadata': {
                            'start_position': start_pos,
                            'end_position': start_pos + len(current_chunk),
                            'split_mode': 'sentence'
                        }
                    })
                    chunk_index += 1
                    start_pos += len(current_chunk)
                
                current_chunk = sentence
        
        # 保存最后一块
        if current_chunk:
            chunks.append({
                'content': current_chunk,
                'chunk_index': chunk_index,
                'char_count': len(current_chunk),
                'token_count': self.estimate_token_count(current_chunk),
                'metadata': {
                    'start_position': start_pos,
                    'end_position': start_pos + len(current_chunk),
                    'split_mode': 'sentence'
                }
            })
        
        return chunks
    
    def _split_long_paragraph(self, paragraph: str, start_index: int, start_pos: int) -> List[Dict[str, Any]]:
        """切分过长的段落"""
        chunks = []
        start = 0
        para_len = len(paragraph)
        
        while start < para_len:
            end = min(start + self.chunk_size, para_len)
            chunk_text = paragraph[start:end].strip()
            
            if chunk_text:
                chunks.append({
                    'content': chunk_text,
                    'chunk_index': start_index + len(chunks),
                    'char_count': len(chunk_text),
                    'token_count': self.estimate_token_count(chunk_text),
                    'metadata': {
                        'start_position': start_pos + start,
                        'end_position': start_pos + end,
                        'split_mode': 'paragraph_long'
                    }
                })
            
            start = end
        
        return chunks
    
    @staticmethod
    def estimate_token_count(text: str) -> int:
        """
        估算token数量
        中文按1个字符=1个token，英文按4个字符=1个token估算
        """
        chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', text))
        other_chars = len(text) - chinese_chars
        return chinese_chars + (other_chars // 4)
    
    @staticmethod
    def detect_encoding(content: bytes, return_confidence: bool = False) -> str:
        """
        检测文件编码
        
        Args:
            content: 文件内容（bytes）
            return_confidence: 是否返回置信度信息
        
        Returns:
            str: 检测到的编码名称（如'utf-8', 'gbk', 'gb2312'等）
            或 tuple: (编码名称, 置信度) if return_confidence=True
        """
        # 使用 chardet 检测编码
        detected = chardet.detect(content)
        encoding = detected.get('encoding', 'utf-8')
        confidence = detected.get('confidence', 0.0)
        
        # 如果置信度太低，尝试常见编码
        if confidence < 0.7:
            # 中文常见编码列表
            common_encodings = ['utf-8', 'gbk', 'gb2312', 'gb18030', 'big5']
            
            for enc in common_encodings:
                try:
                    content.decode(enc)
                    encoding = enc
                    confidence = 0.99  # 手动设置高置信度
                    break
                except (UnicodeDecodeError, LookupError):
                    continue
        
        # 编码名称标准化
        if encoding:
            encoding = encoding.lower()
            # GB2312 是 GBK 的子集，使用 GBK 更保险
            if encoding in ['gb2312', 'gb18030']:
                encoding = 'gbk'
        else:
            encoding = 'utf-8'
        
        if return_confidence:
            return encoding, confidence
        return encoding


class TxtParser(DocumentParser):
    """纯文本文档解析器"""
    
    def parse(self, content: bytes) -> str:
        """
        解析TXT文件，智能处理编码
        
        Args:
            content: 文件内容（bytes）
        
        Returns:
            str: 解析后的文本
        
        Raises:
            ValueError: 如果文件无法解码
        """
        import logging
        logger = logging.getLogger(__name__)
        
        # 自动检测编码
        encoding, confidence = self.detect_encoding(content, return_confidence=True)
        logger.info(f"检测到文件编码: {encoding} (置信度: {confidence:.2%})")
        
        # 尝试使用检测到的编码
        text = None
        try:
            text = content.decode(encoding)
            logger.info(f"成功使用 {encoding} 编码解析文件")
        except (UnicodeDecodeError, LookupError) as e:
            logger.warning(f"使用 {encoding} 解码失败: {str(e)}")
            
            # 尝试常见编码
            fallback_encodings = ['utf-8', 'gbk', 'gb2312', 'gb18030', 'latin-1', 'cp1252']
            for fallback_enc in fallback_encodings:
                if fallback_enc == encoding:
                    continue  # 跳过已经尝试过的
                try:
                    text = content.decode(fallback_enc)
                    logger.info(f"回退使用 {fallback_enc} 编码成功")
                    break
                except (UnicodeDecodeError, LookupError):
                    continue
            
            # 如果所有编码都失败，使用 UTF-8 并忽略错误
            if text is None:
                logger.warning("所有编码尝试失败，使用 UTF-8 并忽略错误字符")
                text = content.decode('utf-8', errors='replace')
                # 替换掉乱码字符
                text = text.replace('�', '')
        
        # 检查是否有过多的乱码字符（可能编码错误）
        if text:
            invalid_ratio = text.count('�') / len(text) if len(text) > 0 else 0
            if invalid_ratio > 0.1:  # 超过10%是乱码
                logger.error(f"文件包含过多乱码字符 ({invalid_ratio:.1%})，可能编码识别错误")
                raise ValueError(f"文件编码错误，包含 {invalid_ratio:.1%} 的乱码字符。请确保文件使用 UTF-8、GBK 或 GB2312 编码")
        
        # 规范化换行符
        text = text.replace('\r\n', '\n').replace('\r', '\n')
        
        # 去除多余的空行（保留一个）
        text = re.sub(r'\n{3,}', '\n\n', text)
        
        # 去除 BOM 标记
        if text.startswith('\ufeff'):
            text = text[1:]
        
        return text.strip()


class MarkdownParser(DocumentParser):
    """Markdown文档解析器"""
    
    def parse(self, content: bytes) -> str:
        """
        解析Markdown文件，智能处理编码
        
        Args:
            content: 文件内容（bytes）
        
        Returns:
            str: 解析后的文本
        
        Raises:
            ValueError: 如果文件无法解码
        """
        import logging
        logger = logging.getLogger(__name__)
        
        text = None
        
        # Markdown通常是UTF-8编码，优先尝试
        try:
            text = content.decode('utf-8')
            logger.info("成功使用 UTF-8 编码解析 Markdown 文件")
        except UnicodeDecodeError:
            logger.warning("UTF-8 解码失败，尝试自动检测编码")
            
            # 回退到自动检测
            encoding, confidence = self.detect_encoding(content, return_confidence=True)
            logger.info(f"检测到文件编码: {encoding} (置信度: {confidence:.2%})")
            
            try:
                text = content.decode(encoding)
                logger.info(f"成功使用 {encoding} 编码解析文件")
            except (UnicodeDecodeError, LookupError):
                logger.warning(f"使用 {encoding} 解码失败，尝试其他编码")
                
                # 尝试其他常见编码
                fallback_encodings = ['gbk', 'gb2312', 'gb18030', 'latin-1']
                for fallback_enc in fallback_encodings:
                    if fallback_enc == encoding:
                        continue
                    try:
                        text = content.decode(fallback_enc)
                        logger.info(f"回退使用 {fallback_enc} 编码成功")
                        break
                    except (UnicodeDecodeError, LookupError):
                        continue
                
                # 最后的回退：UTF-8 with replace
                if text is None:
                    logger.warning("所有编码尝试失败，使用 UTF-8 并替换错误字符")
                    text = content.decode('utf-8', errors='replace')
                    text = text.replace('�', '')
        
        # 检查乱码比例
        if text:
            invalid_ratio = text.count('�') / len(text) if len(text) > 0 else 0
            if invalid_ratio > 0.1:
                logger.error(f"Markdown 文件包含过多乱码字符 ({invalid_ratio:.1%})")
                raise ValueError(f"文件编码错误，包含 {invalid_ratio:.1%} 的乱码字符。建议使用 UTF-8 编码保存 Markdown 文件")
        
        # 规范化换行符
        text = text.replace('\r\n', '\n').replace('\r', '\n')
        
        # 去除 BOM 标记
        if text.startswith('\ufeff'):
            text = text[1:]
        
        return text.strip()
    
    def split_into_chunks(self, text: str) -> List[Dict[str, Any]]:
        """
        Markdown智能切分
        优先按标题层级切分，其次按段落
        """
        if not text or not text.strip():
            return []
        
        # 尝试按标题切分
        chunks = self._split_by_headers(text)
        
        # 如果没有标题或者块太大，使用默认切分
        if not chunks or any(len(c['content']) > self.chunk_size * 2 for c in chunks):
            return super().split_into_chunks(text)
        
        return chunks
    
    def _split_by_headers(self, text: str) -> List[Dict[str, Any]]:
        """按Markdown标题切分"""
        # 匹配Markdown标题（# ## ### 等）
        header_pattern = re.compile(r'^(#{1,6})\s+(.+)$', re.MULTILINE)
        
        chunks = []
        chunk_index = 0
        last_pos = 0
        
        # 提取所有标题位置
        headers = [(m.start(), m.end(), m.group(1), m.group(2)) 
                   for m in header_pattern.finditer(text)]
        
        if not headers:
            return []
        
        # 按标题切分
        for i, (start, end, level, title) in enumerate(headers):
            # 获取到下一个标题之前的内容
            if i < len(headers) - 1:
                next_start = headers[i + 1][0]
                chunk_text = text[start:next_start].strip()
            else:
                chunk_text = text[start:].strip()
            
            if chunk_text:
                chunks.append({
                    'content': chunk_text,
                    'chunk_index': chunk_index,
                    'char_count': len(chunk_text),
                    'token_count': self.estimate_token_count(chunk_text),
                    'metadata': {
                        'header_level': len(level),
                        'header_title': title,
                        'start_position': start,
                        'end_position': start + len(chunk_text)
                    }
                })
                chunk_index += 1
        
        return chunks


def get_parser(file_type: str, chunk_size: int = 500, chunk_overlap: int = 50) -> DocumentParser:
    """
    获取文档解析器
    
    Args:
        file_type: 文件类型（txt/md）
        chunk_size: 文本块大小
        chunk_overlap: 文本块重叠大小
    
    Returns:
        DocumentParser: 对应的解析器实例
    """
    if file_type.lower() == 'txt':
        return TxtParser(chunk_size, chunk_overlap)
    elif file_type.lower() == 'md':
        return MarkdownParser(chunk_size, chunk_overlap)
    else:
        raise ValueError(f"不支持的文件类型: {file_type}")


def parse_and_split_document(
    content: bytes, 
    file_type: str, 
    chunk_size: int = 500, 
    chunk_overlap: int = 50,
    split_mode: str = 'fixed'
) -> Tuple[str, List[Dict[str, Any]]]:
    """
    解析文档并切分为文本块（便捷函数）
    
    Args:
        content: 文档内容（bytes）
        file_type: 文件类型（txt/md）
        chunk_size: 文本块大小
        chunk_overlap: 文本块重叠大小
        split_mode: 切分模式 ('fixed'|'paragraph'|'sentence'|'custom')
    
    Returns:
        tuple: (解析后的文本, 文本块列表)
    """
    parser = get_parser(file_type, chunk_size, chunk_overlap)
    text = parser.parse(content)
    chunks = parser.split_into_chunks(text, mode=split_mode)
    return text, chunks

