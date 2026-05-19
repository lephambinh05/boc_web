
from fpdf import FPDF
import os

class TechnicalFeedbackPDF(FPDF):
    def header(self):
        self.set_fill_color(46, 26, 26) # Dark Red for error feedback
        self.rect(0, 0, 210, 35, 'F')
        self.set_y(10)
        self.set_font("Arial", "B", 20)
        self.set_text_color(255, 255, 255)
        self.cell(0, 10, "TECHNICAL FEEDBACK REPORT", new_x="LMARGIN", new_y="NEXT", align="C")
        self.set_font("Arial", "", 12)
        self.cell(0, 8, "Issue: Build Command Syntax Error", new_x="LMARGIN", new_y="NEXT", align="C")
        self.ln(10)

    def footer(self):
        self.set_y(-20)
        self.set_fill_color(245, 245, 245)
        self.rect(0, 277, 210, 20, 'F')
        self.set_font("Arial", "I", 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 10, f"Technical Audit - PixelSlide Project 2026 | Trang {self.page_no()}/{{nb}}", align="C")

    def section_title(self, title):
        self.ln(5)
        self.set_font("Arial", "B", 14)
        self.set_text_color(180, 0, 0)
        self.cell(0, 10, title.upper(), new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(180, 0, 0)
        self.set_line_width(0.5)
        self.line(self.get_x(), self.get_y(), self.get_x() + 190, self.get_y())
        self.ln(4)

    def body_text(self, text):
        self.set_font("Arial", "", 10)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(2)

def generate_feedback_pdf():
    pdf = TechnicalFeedbackPDF()
    font_path = r"C:\Windows\Fonts\Arial.ttf"
    if os.path.exists(font_path):
        pdf.add_font("Arial", "", font_path)
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_y(40)

    pdf.section_title("1. Phân tích lỗi (Error Analysis)")
    pdf.body_text("Lệnh bạn vừa chạy: 'flutter run build'")
    pdf.body_text("Vấn đề: Lệnh 'flutter run' dùng để chạy ứng dụng trên thiết bị và nó mong đợi tham số là một file (như lib/main.dart). Bạn đã truyền 'build', nên Flutter tìm file tên là 'build' và không thấy.")

    pdf.section_title("2. Hướng dẫn sửa lỗi (Correction Guide)")
    pdf.body_text("Nếu bạn muốn chạy ứng dụng:")
    pdf.body_text("- flutter run")
    pdf.body_text("Nếu bạn muốn biên dịch (build) ứng dụng:")
    pdf.body_text("- flutter build web (Dành cho web)")
    pdf.body_text("- flutter build apk --release (Dành cho Android)")

    pdf.section_title("3. Đánh giá kỹ thuật (Technical Score)")
    pdf.body_text("Điểm: 4.0 / 10")
    pdf.body_text("- Trừ điểm: Sai cú pháp lệnh cơ bản.")
    pdf.body_text("- Trừ điểm: Chưa xác định rõ môi trường đích (target environment).")

    output_file = "Technical_Feedback_BuildError.pdf"
    pdf.output(output_file)
    print(f"PDF generated successfully: {os.path.abspath(output_file)}")

if __name__ == "__main__":
    generate_feedback_pdf()
