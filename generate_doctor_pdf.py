
from fpdf import FPDF
import os

class DoctorReportPDF(FPDF):
    def header(self):
        self.set_fill_color(0, 50, 100) # Dark Blue
        self.rect(0, 0, 210, 35, 'F')
        self.set_y(10)
        self.set_font("Arial", "B", 20)
        self.set_text_color(255, 255, 255)
        self.cell(0, 10, "FLUTTER DOCTOR AUDIT REPORT", new_x="LMARGIN", new_y="NEXT", align="C")
        self.set_font("Arial", "", 12)
        self.cell(0, 8, "Diagnosis & Resolution Steps", new_x="LMARGIN", new_y="NEXT", align="C")
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
        self.set_text_color(0, 50, 150)
        self.cell(0, 10, title.upper(), new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(0, 50, 150)
        self.set_line_width(0.5)
        self.line(self.get_x(), self.get_y(), self.get_x() + 190, self.get_y())
        self.ln(4)

    def body_text(self, text):
        self.set_font("Arial", "", 10)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(2)

def generate_doctor_pdf():
    pdf = DoctorReportPDF()
    font_path = r"C:\Windows\Fonts\Arial.ttf"
    font_bold_path = r"C:\Windows\Fonts\Arialbd.ttf"
    
    if os.path.exists(font_path):
        pdf.add_font("Arial", "", font_path)
    if os.path.exists(font_bold_path):
        pdf.add_font("Arial", "B", font_bold_path)
        
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_y(40)

    pdf.section_title("1. Phan tich trang thai (System Analysis)")
    pdf.body_text("Flutter Doctor phat hien 2 van de nghiem trọng:")
    pdf.body_text("- Android Toolchain: Thieu cmdline-tools va chua chap nhan license.")
    pdf.body_text("- Visual Studio: Thieu cac thanh phan C++ (chi can thiet neu build Windows Desktop).")

    pdf.section_title("2. Cac buoc khac phuc (Resolution Steps)")
    pdf.body_text("Buoc 1: Cai dat Android SDK Command-line Tools")
    pdf.body_text("1. Mo Android Studio.")
    pdf.body_text("2. Settings > Languages & Frameworks > Android SDK.")
    pdf.body_text("3. Chon tab SDK Tools.")
    pdf.body_text("4. Tich vao 'Android SDK Command-line Tools (latest)'.")
    pdf.body_text("5. Bam Apply va doi cai dat xong.")
    
    pdf.body_text("Buoc 2: Chap nhan Android Licenses")
    pdf.body_text("Sau khi xong buoc 1, chay lenh sau trong Terminal:")
    pdf.body_text("flutter doctor --android-licenses")
    pdf.body_text("Bam 'y' cho tat ca cac cau hoi.")

    pdf.section_title("3. Danh gia ky thuat (Technical Score)")
    pdf.body_text("Diem: 7.5 / 10")
    pdf.body_text("- Diem cong: Moi truong Flutter va Chrome da san sang.")
    pdf.body_text("- Diem tru: Android Toolchain chua duoc cau hinh day du.")

    output_file = "Flutter_Doctor_Audit.pdf"
    pdf.output(output_file)
    print(f"PDF generated successfully: {os.path.abspath(output_file)}")

if __name__ == "__main__":
    generate_doctor_pdf()
