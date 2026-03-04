using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace INVARIX
{
    public partial class frmDashboard : Form
    {
        // Khai báo một biến để lưu tên tài khoản đang đăng nhập
        private string loggedInUsername;

        // Sửa lại hàm khởi tạo (thêm chữ 'string username' vào trong ngoặc)
        public frmDashboard(string username)
        {
            InitializeComponent();

            // Lưu lại tên đăng nhập được truyền từ form Login sang
            loggedInUsername = username;

            // Tùy chọn: Đổi luôn tiêu đề của cửa sổ để chào người dùng
            this.Text = "INVARIX - Xin chào: " + loggedInUsername;
        }

        private void menuDoiMatKhau_Click(object sender, EventArgs e)
        {
            this.Hide(); 

            frmDoiMatKhau formDoiMK = new frmDoiMatKhau(loggedInUsername);

            formDoiMK.FormClosed += (s, args) => this.Show();

            formDoiMK.Show(); 
        }

        private void menuDangXuat_Click(object sender, EventArgs e)
        {
            // Hiển thị hộp thoại hỏi người dùng có chắc chắn muốn đăng xuất không
            DialogResult result = MessageBox.Show("Bạn có chắc chắn muốn đăng xuất khỏi hệ thống?", "Xác nhận đăng xuất", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

            if (result == DialogResult.Yes)
            {
                this.Hide(); // Ẩn Dashboard hiện tại

                // Tạo và hiển thị lại Form Đăng nhập
                Login formLogin = new Login();
                formLogin.Show();
            }
        }

        // Tắt hẳn phần mềm nếu bạn bấm dấu X tắt Dashboard
        private void frmDashboard_FormClosed(object sender, FormClosedEventArgs e)
        {
            Application.Exit();
        }

        private void menuTinhGia_Click(object sender, EventArgs e)
        {
            this.Hide(); 

            frmTinhGia formTinhGia = new frmTinhGia();
            
            formTinhGia.FormClosed += (s, args) => this.Show();

            formTinhGia.Show(); 
        }
    }
}
