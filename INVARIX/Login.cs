using INVARIX;
using System;
using System.Data.SqlClient;
using System.Windows.Forms;

namespace INVARIX
{
    public partial class Login : Form
    {
        public Login()
        {
            InitializeComponent();
            this.StartPosition = FormStartPosition.CenterScreen;
        }

        private void btnLogin_Click(object sender, EventArgs e)
        {
            string username = txtUsername.Text.Trim();
            string password = txtPassword.Text.Trim();

            // Kiểm tra xem người dùng có để trống không
            if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
            {
                MessageBox.Show("Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // Gọi hàm kiểm tra đăng nhập
            if (CheckLogin(username, password))
            {
                MessageBox.Show("Đăng nhập thành công!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Information);

                // Mở form Dashboard
                frmDashboard dashboard = new frmDashboard(txtUsername.Text.Trim());
                dashboard.Show();

                // Ẩn form Login đi
                this.Hide();
            }
            else
            {
                MessageBox.Show("Sai tên đăng nhập hoặc mật khẩu!", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // Hàm kết nối SQL và kiểm tra tài khoản
        private bool CheckLogin(string username, string password)
        {
            bool isValid = false;

            // Sử dụng "using" để tự động đóng kết nối sau khi dùng xong
            // ĐÃ CẬP NHẬT: Sử dụng chuỗi kết nối từ class CauHinhKetNoi
            using (SqlConnection conn = new SqlConnection(CauHinhKetNoi.ChuoiKetNoi))
            {
                try
                {
                    conn.Open();
                    // Sử dụng tham số (@user, @pass) để bảo mật, chống lỗi SQL Injection
                    string query = "SELECT COUNT(1) FROM [users] WHERE email = @user AND password = @pass";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@user", username);
                        cmd.Parameters.AddWithValue("@pass", password);

                        // Thực thi câu lệnh và lấy kết quả
                        int count = Convert.ToInt32(cmd.ExecuteScalar());
                        if (count == 1)
                        {
                            isValid = true;
                        }
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi kết nối cơ sở dữ liệu: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
            return isValid;
        }

        private void frmLogin_Load(object sender, EventArgs e)
        {

        }
    }
}