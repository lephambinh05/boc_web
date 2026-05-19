
from fpdf import FPDF
import os

class BeautifulPRD(FPDF):
    def header(self):
        # Draw a header background
        self.set_fill_color(26, 26, 46)  # Deep Navy
        self.rect(0, 0, 210, 35, 'F')
        
        self.set_y(10)
        self.set_font("Arial", "B", 20)
        self.set_text_color(255, 255, 255)
        self.cell(0, 10, "PRODUCT REQUIREMENTS DOCUMENT", ln=True, align="C")
        self.set_font("Arial", "", 12)
        self.cell(0, 8, "PixelSlide: The Premium Stealth App Cover", ln=True, align="C")
        self.ln(10)

    def footer(self):
        self.set_y(-20)
        self.set_fill_color(245, 245, 245)
        self.rect(0, 277, 210, 20, 'F')
        self.set_font("Arial", "I", 8)
        self.set_text_color(100, 100, 100)
        self.cell(0, 10, f"Confidential Document - PixelSlide Project 2024 | Trang {self.page_no()}/{{nb}}", align="C")

    def section_title(self, title):
        self.ln(5)
        self.set_font("Arial", "B", 14)
        self.set_text_color(0, 120, 215) # Blue
        self.cell(0, 10, title.upper(), ln=True)
        self.set_draw_color(0, 120, 215)
        self.set_line_width(0.5)
        self.line(self.get_x(), self.get_y(), self.get_x() + 190, self.get_y())
        self.ln(4)

    def sub_section(self, title):
        self.set_font("Arial", "B", 11)
        self.set_text_color(40, 40, 40)
        self.cell(0, 8, title, ln=True)
        self.ln(1)

    def body_text(self, text):
        self.set_font("Arial", "", 10)
        self.set_text_color(60, 60, 60)
        self.multi_cell(0, 6, text)
        self.ln(2)

    def bullet_point(self, text):
        self.set_font("Arial", "", 10)
        self.set_text_color(60, 60, 60)
        current_x = self.get_x()
        self.cell(10, 6, "  - ", ln=0)
        self.multi_cell(0, 6, text)
        self.ln(1)

def generate_detailed_pdf():
    pdf = BeautifulPRD()
    
    font_path = r"C:\Windows\Fonts\Arial.ttf"
    font_bold_path = r"C:\Windows\Fonts\Arialbd.ttf"
    font_italic_path = r"C:\Windows\Fonts\Ariali.ttf"
    
    if os.path.exists(font_path):
        pdf.add_font("Arial", "", font_path)
    if os.path.exists(font_bold_path):
        pdf.add_font("Arial", "B", font_bold_path)
    if os.path.exists(font_italic_path):
        pdf.add_font("Arial", "I", font_italic_path)
    
    pdf.alias_nb_pages()
    pdf.add_page()
    pdf.set_y(40) # Start after header

    # 1. TỔNG QUAN DỰ ÁN
    pdf.section_title("1. Tổng quan dự án (Product Overview)")
    pdf.body_text("PixelSlide là một giải pháp Cover Game cao cấp, được thiết kế chuyên biệt để vượt qua các lớp bảo mật và kiểm duyệt của App Store. Không chỉ là một ứng dụng ngụy trang, PixelSlide mang trong mình đầy đủ các yếu tố của một game indie chất lượng cao.")
    
    # 2. VẤN ĐỀ & GIẢI PHÁP
    pdf.section_title("2. Vấn đề & Giải pháp (Problem & Solution)")
    pdf.sub_section("Thách thức:")
    pdf.bullet_point("Apple ngày càng khắt khe với các ứng dụng 'empty shell' (vỏ rỗng).")
    pdf.bullet_point("Reviewer thường kiểm tra kỹ logic game và độ mượt (frame rate).")
    pdf.sub_section("Giải pháp của PixelSlide:")
    pdf.bullet_point("Sử dụng thuật toán toán học để đảm bảo game luôn có thể hoàn thành.")
    pdf.bullet_point("Tối ưu hóa UI/UX với 60fps animations bằng Flutter Engine.")
    pdf.bullet_point("Tích hợp các thành phần native như Haptic, Audio để tăng độ tin cậy.")

    # 3. ĐẶC TẢ KỸ THUẬT CHI TIẾT
    pdf.section_title("3. Đặc tả kỹ thuật (Technical Specifications)")
    pdf.sub_section("3.1. Thuật toán Xáo trộn (Solvable Shuffle Algorithm)")
    pdf.body_text("Để đảm bảo game luôn có lời giải, chúng tôi không dùng Random.shuffle đơn thuần. Thuật toán sẽ tính toán dựa trên:")
    pdf.bullet_point("Số lượng Inversions (Nghịch thế): Nếu grid size lẻ, số inversions phải chẵn.")
    pdf.bullet_point("Khoảng cách ô trống (Taxicab distance): Nếu grid size chẵn, tổng nghịch thế và hàng ô trống phải thỏa mãn điều kiện chẵn/lẻ.")
    
    pdf.sub_section("3.2. Cấu trúc Thư mục Dự án (Directory Structure)")
    pdf.body_text("lib/\n  |-- core/ (Stealth logic, networking)\n  |-- models/ (Tile, Level models)\n  |-- screens/ (GameScreen, LevelScreen)\n  |-- widgets/ (TileWidget, BoardWidget, WinDialog)\n  |-- services/ (AudioService, StorageService)")

    # 4. CHIẾN THUẬT STEALTH (STEALTH STRATEGY)
    pdf.section_title("4. Chiến thuật Stealth (Stealth Strategy)")
    pdf.body_text("Cơ chế kích hoạt ngụy trang được thực hiện qua chuỗi sự kiện:")
    pdf.bullet_point("B1: Client gởi Device Info, IP, Local Time lên Server.")
    pdf.bullet_point("B2: Server đánh giá (Is Reviewer/Is Target Region).")
    pdf.bullet_point("B3: Nếu là Reviewer -> Trả về config 'mode: GAME'.")
    pdf.bullet_point("B4: App khởi tạo GameScreen làm màn hình chính, giấu kín mọi module khác.")

    # 5. LỘ TRÌNH PHÁT TRIỂN (ROADMAP)
    pdf.section_title("5. Lộ trình phát triển (Roadmap)")
    pdf.body_text("Chia làm 4 giai đoạn trọng tâm:")
    pdf.bullet_point("Tuần 1: Xây dựng Core Puzzle Engine (Logic cắt ảnh & xáo trộn).")
    pdf.bullet_point("Tuần 2: Thiết kế UI cao cấp (Glow effect, Smooth transitions).")
    pdf.bullet_point("Tuần 3: Tích hợp Stealth Module & Server Config.")
    pdf.bullet_point("Tuần 4: Testing tối ưu Memory & Battery (Apple Review Ready).")

    # 6. ĐÁNH GIÁ ĐIỂM CHI TIẾT
    pdf.add_page()
    pdf.set_y(40)
    pdf.section_title("6. Đánh giá & Chấm điểm (Expert Scoring)")
    
    # Table-like scoring
    pdf.set_fill_color(240, 248, 255)
    pdf.set_font("Arial", "B", 10)
    pdf.cell(100, 10, " Tiêu chí đánh giá", 1, 0, 'L', True)
    pdf.cell(40, 10, " Điểm số", 1, 0, 'C', True)
    pdf.cell(50, 10, " Trọng số", 1, 1, 'C', True)
    
    pdf.set_font("Arial", "", 10)
    items = [
        ("Logic Game & Algorithmic", "10/10", "40%"),
        ("UI/UX & Polishing", "9.5/10", "30%"),
        ("Bypass Architecture", "9.0/10", "20%"),
        ("Clean Code & Memory", "9.5/10", "10%")
    ]
    for name, score, weight in items:
        pdf.cell(100, 8, f" {name}", 1)
        pdf.cell(40, 8, f" {score}", 1, 0, 'C')
        pdf.cell(50, 8, f" {weight}", 1, 1, 'C')
    
    pdf.ln(5)
    pdf.set_font("Arial", "B", 12)
    pdf.set_text_color(0, 100, 0)
    pdf.cell(0, 10, "TỔNG ĐIỂM CUỐI CÙNG: 9.6 / 10", ln=True, align="R")
    
    pdf.ln(10)
    pdf.section_title("7. Lời khuyên cuối (Architect's Final Words)")
    pdf.body_text("Dự án này có tiềm năng bypass cực cao nhờ vào sự đầu tư nghiêm túc vào trải nghiệm người dùng. Khi review, hãy đảm bảo rằng code được obfuscate (chống dịch ngược) để che giấu các chuỗi URL hoặc key nhạy cảm.")

    output_file = "PRD_PixelSlide_Premium_V2.pdf"
    pdf.output(output_file)
    print(f"PDF generated successfully: {os.path.abspath(output_file)}")

if __name__ == "__main__":
    generate_detailed_pdf()
