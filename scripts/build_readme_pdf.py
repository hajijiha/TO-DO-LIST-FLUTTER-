"""Render the project's Korean README and actual screenshots to a printable PDF."""

from __future__ import annotations

import re
from pathlib import Path
from xml.sax.saxutils import escape

from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, Image, KeepTogether, NextPageTemplate, PageBreak,
    PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output' / 'pdf' / 'Readme.pdf'
FONT = Path('C:/Windows/Fonts')
pdfmetrics.registerFont(TTFont('Korean', str(FONT / 'malgun.ttf')))
pdfmetrics.registerFont(TTFont('KoreanBold', str(FONT / 'malgunbd.ttf')))
pdfmetrics.registerFontFamily('Korean', normal='Korean', bold='KoreanBold')
TEAL = colors.HexColor('#174D4B')
MUTED = colors.HexColor('#64736F')
styles = getSampleStyleSheet()
styles.add(ParagraphStyle('KRBody', fontName='Korean', fontSize=9.2, leading=15,
                          textColor=colors.HexColor('#263D37'), spaceAfter=6,
                          wordWrap='CJK'))
styles.add(ParagraphStyle('KRTitle', fontName='KoreanBold', fontSize=25, leading=34,
                          textColor=TEAL, spaceAfter=18, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH2', fontName='KoreanBold', fontSize=15, leading=22,
                          textColor=TEAL, spaceBefore=14, spaceAfter=9,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRH3', fontName='KoreanBold', fontSize=11, leading=17,
                          textColor=TEAL, spaceBefore=9, spaceAfter=5,
                          keepWithNext=True, wordWrap='CJK'))
styles.add(ParagraphStyle('KRCode', fontName='Korean', fontSize=8.0, leading=12,
                          backColor=colors.HexColor('#EFF3F0'), borderPadding=8,
                          spaceBefore=3, spaceAfter=9, wordWrap='CJK'))
styles.add(ParagraphStyle('KRCell', parent=styles['KRBody'], fontSize=8.0,
                          leading=12, spaceAfter=0))
styles.add(ParagraphStyle('KRCaption', parent=styles['KRBody'], fontSize=8.8,
                          leading=14, textColor=MUTED, spaceAfter=9))
styles.add(ParagraphStyle('KRBullet', parent=styles['KRBody'], leading=13,
                          spaceAfter=3))


class CodeParagraph(Paragraph):
    """Keep the project's short command and structure blocks on one page."""

    def split(self, availWidth, availHeight):
        return []


def inline(text: str) -> str:
    text = escape(text)
    text = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',
                  r'<link href="\2" color="#176B60">\1</link>', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', text)
    text = re.sub(r'`([^`]+)`', r'<font color="#176B60">\1</font>', text)
    return text


def footer(canvas, document):
    width, height = canvas._pagesize
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor('#DCE5DF'))
    canvas.line(40, 38, width - 40, 38)
    canvas.setFont('Korean', 8)
    canvas.setFillColor(MUTED)
    canvas.drawString(40, 24, '오늘 할 일 · 하루 기록 | Flutter + Riverpod | v2.0')
    canvas.drawRightString(width - 40, 24, str(document.page))
    canvas.restoreState()


def table_flow(rows):
    content = [[Paragraph(inline(cell), styles['KRCell']) for cell in row]
               for row in rows]
    columns = len(rows[0])
    available = A4[0] - 80
    fractions = {2: [0.32, 0.68], 3: [0.24, 0.33, 0.43],
                 4: [0.16, 0.31, 0.38, 0.15]}.get(columns,
                                               [1 / columns] * columns)
    table = Table(content, colWidths=[available * x for x in fractions],
                  repeatRows=1, hAlign='LEFT')
    table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#E5ECE7')),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 7),
        ('RIGHTPADDING', (0, 0), (-1, -1), 7),
        ('TOPPADDING', (0, 0), (-1, -1), 7),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
        ('LINEBELOW', (0, 0), (-1, 0), 0.7, colors.HexColor('#B6CDC2')),
        ('LINEBELOW', (0, 1), (-1, -1), 0.3, colors.HexColor('#DCE5DF')),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1),
         [colors.white, colors.HexColor('#F7F9F7')]),
    ]))
    return [table, Spacer(1, 9)]


def markdown_flow(source):
    result = []
    lines = source.splitlines()
    index = 0
    while index < len(lines):
        line = lines[index].strip()
        if not line:
            index += 1
            continue
        if line.startswith('```'):
            index += 1
            code = []
            while index < len(lines) and not lines[index].strip().startswith('```'):
                code.append(escape(lines[index]).replace(' ', '&nbsp;'))
                index += 1
            result.append(CodeParagraph('<br/>'.join(code), styles['KRCode']))
        elif line.startswith('|'):
            rows = []
            while index < len(lines) and lines[index].strip().startswith('|'):
                cells = [item.strip() for item in lines[index].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\-\s]+', item) for item in cells):
                    rows.append(cells)
                index += 1
            result.extend(table_flow(rows))
            continue
        elif line.startswith('!['):
            # Images are collected as large, labeled appendix pages below.
            match = re.match(r'!\[(.*?)\]\((.*?)\)', line)
            if match:
                result.append(Paragraph('실행 화면: ' + inline(match[1]) +
                                        ' (뒤의 실제 캡처 부록 참조)', styles['KRCaption']))
        elif line.startswith('# '):
            result.append(Paragraph(inline(line[2:]), styles['KRTitle']))
        elif line.startswith('## '):
            result.append(Paragraph(inline(line[3:]), styles['KRH2']))
        elif line.startswith('### '):
            result.append(Paragraph(inline(line[4:]), styles['KRH3']))
        elif re.match(r'^[-*] ', line):
            bullets = []
            while index < len(lines) and re.match(r'^[-*] ', lines[index].strip()):
                bullets.append('• ' + inline(lines[index].strip()[2:]))
                index += 1
            result.append(Paragraph('<br/>'.join(bullets), styles['KRBullet']))
            continue
        elif re.match(r'^\d+\. ', line):
            result.append(Paragraph(inline(line), styles['KRBody']))
        elif line == '---':
            result.append(Spacer(1, 6))
        else:
            result.append(Paragraph(inline(line), styles['KRBody']))
        index += 1
    return result


def screenshot_flow():
    captions = [
        ('01_list.png', '리스트', 'Windows 네이티브 앱에서 할 일 3개의 장소, 예상 시간, 미완료 상태를 표시한 화면.'),
        ('02_add_input.png', '추가 전 입력', '새 제목 "DevTools 화면 캡처", 장소 "컴퓨터실", 예상 시간 45분을 입력한 화면.'),
        ('03_add_result.png', '추가 결과', 'DevTools 화면 캡처 항목이 추가되어 전체 목록이 4개가 된 화면.'),
        ('04_delete_before.png', '삭제 전', '삭제 대상 "Riverpod 구조 정리"가 포함된 4개 항목.'),
        ('05_delete_after.png', '삭제 결과', '"Riverpod 구조 정리"가 삭제되고 다른 3개 항목이 남은 화면. 삭제 후 기준 작업량은 유지된다.'),
        ('06_devtools_inspector.png', 'DevTools Inspector', 'debug 네이티브 앱의 위젯 트리와 속성 검사.'),
        ('07_devtools_timeline.png', 'DevTools Timeline', 'Windows profile 앱의 실제 프레임 타임라인과 이벤트 상세 화면.'),
        ('08_devtools_memory.png', 'DevTools Memory', 'Windows profile 앱의 실제 메모리 사용량과 객체 할당 관찰 화면.'),
        ('09_devtools_performance.png', 'DevTools Performance', 'Windows profile 앱의 프레임 그래프와 선택 프레임 분석 화면.'),
        ('10_rating_dialog.png', '완료와 수행 평점', '완료 체크 후 0~10점 수행 점수를 입력하는 화면. 0점도 완료 상태로 저장된다.'),
        ('11_daily_score.png', '하루 점수와 작업량', '완료 평점 평균 8.5점과 개수·시간을 반영한 하루 점수 3.7점을 구분해 표시한다.'),
        ('12_calendar_history.png', '달력 기록', '달력에서 지난 날짜를 선택해 완료된 할 일과 날짜별 점수를 조회한다. 촬영용 과거 기록은 예시 자료다.'),
        ('13_edit_dialog.png', '할 일 수정', '제목, 장소, 예상 시간, 날짜를 수정하는 화면.'),
        ('14_goal_settings.png', '하루 목표 설정', '기본 개수·시간 목표를 설정한다. 새 기록일에 적용하고 이미 기록한 날짜의 기준은 유지한다.'),
        ('15_place_catalog.png', '입력한 장소 재사용', '공부 카테고리에서 사용자가 입력했던 도서관을 자동완성 후보로 표시한다.'),
        ('16_place_stats.png', '카테고리별 장소 기록', '장소별 8점 이상 완료 비율, 평균 평점, 표본 수와 완료 예상시간을 표시한다. 미래 계획은 제외한다.'),
        ('17_day_reflection.png', '직접 쓰는 하루 피드백', '잘한 점, 미흡했던 점, 다음에 개선할 점을 직접 작성하고 날짜별로 저장한다.'),
        ('18_separate_lists.png', '해야 할 일과 실제로 한 일', '미완료와 완료 항목을 별도 목록으로 표시한다. 완료 평점을 저장하면 실제로 한 일 목록으로 이동한다.'),
    ]
    result = []
    for filename, title, caption in captions:
        path = ROOT / 'docs' / 'screenshots' / filename
        if not path.exists():
            path = path.with_suffix('.jpg')
            if not path.exists():
                continue
        with PILImage.open(path) as source_image:
            width, height = source_image.size
        page_size = A4 if height > width else landscape(A4)
        page_template = 'Portrait' if height > width else 'Landscape'
        available_width = page_size[0] - 80
        available_height = page_size[1] - 190
        result.extend([NextPageTemplate(page_template), PageBreak(),
                       Paragraph('실제 실행 캡처 | ' + title, styles['KRH2']),
                       Paragraph(caption, styles['KRCaption'])])
        scale = min(available_width / width, available_height / height)
        result.append(Image(str(path), width=width * scale, height=height * scale,
                            hAlign='CENTER'))
    return result


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document = BaseDocTemplate(str(OUTPUT), pagesize=A4, title='오늘 할 일 - Readme',
                               author='Flutter To Do Project', leftMargin=40,
                               rightMargin=40, topMargin=42, bottomMargin=52)
    portrait = Frame(40, 52, A4[0] - 80, A4[1] - 94, id='PortraitFrame')
    wide = landscape(A4)
    landscape_frame = Frame(40, 52, wide[0] - 80, wide[1] - 94, id='LandscapeFrame')
    document.addPageTemplates([
        PageTemplate(id='Portrait', frames=[portrait], pagesize=A4, onPage=footer),
        PageTemplate(id='Landscape', frames=[landscape_frame], pagesize=wide, onPage=footer),
    ])
    source = (ROOT / 'README.md').read_text(encoding='utf-8-sig')
    document.build(markdown_flow(source) + screenshot_flow())
    print(OUTPUT)


if __name__ == '__main__':
    main()
