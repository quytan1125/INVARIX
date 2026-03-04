using INVARIX;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace INVARIX
{
    public partial class frmDoiMatKhau : Form
    {
        // Biến lưu tên tài khoản (bây giờ là email) đang đăng nhập
        private string currentUsername;

        // Sửa lại hàm khởi tạo để nhận tên đăng nhập vào
        public frmDoiMatKhau(string username)
        {
            InitializeComponent();
            currentUsername = username;
            this.StartPosition = FormStartPosition.CenterScreen; // Cho form ra giữa màn hình
        }

        private void frmDoiMatKhau_Load(object sender, EventArgs e)
        {

        }

        private void btnLuu_Click(object sender, EventArgs e)
        {
            string oldPass = txtMatKhauCu.Text.Trim();
            string newPass = txtMatKhauMoi.Text.Trim();
            string confirmPass = txtXacNhanMatKhau.Text.Trim();

            // 1. Kiểm tra xem người dùng có nhập thiếu ô nào không
            if (string.IsNullOrEmpty(oldPass) || string.IsNullOrEmpty(newPass) || string.IsNullOrEmpty(confirmPass))
            {
                MessageBox.Show("Vui lòng nhập đầy đủ thông tin!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            // 2. Kiểm tra mật khẩu mới và ô xác nhận có giống nhau không
            if (newPass != confirmPass)
            {
                MessageBox.Show("Mật khẩu mới và xác nhận không khớp!", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // 3. Kết nối CSDL để kiểm tra mật khẩu cũ và cập nhật
            using (SqlConnection conn = new SqlConnection(CauHinhKetNoi.ChuoiKetNoi))
            {
                try
                {
                    conn.Open();

                    // Bước 3a: Kiểm tra mật khẩu cũ có đúng không 
                    string checkQuery = "SELECT COUNT(1) FROM [users] WHERE email = @user AND password = @oldPass";
                    using (SqlCommand cmdCheck = new SqlCommand(checkQuery, conn))
                    {
                        cmdCheck.Parameters.AddWithValue("@user", currentUsername);
                        cmdCheck.Parameters.AddWithValue("@oldPass", oldPass);

                        int count = Convert.ToInt32(cmdCheck.ExecuteScalar());
                        if (count == 0) // Mật khẩu cũ sai
                        {
                            MessageBox.Show("Mật khẩu cũ không chính xác!", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                            return;
                        }
                    }

                    // Bước 3b: Nếu mật khẩu cũ đúng -> Cập nhật mật khẩu mới
                    string updateQuery = "UPDATE [users] SET password = @newPass WHERE email = @user";
                    using (SqlCommand cmdUpdate = new SqlCommand(updateQuery, conn))
                    {
                        cmdUpdate.Parameters.AddWithValue("@newPass", newPass);
                        cmdUpdate.Parameters.AddWithValue("@user", currentUsername);

                        cmdUpdate.ExecuteNonQuery(); // Thực thi lệnh Update

                        MessageBox.Show("Đổi mật khẩu thành công!", "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        this.Close(); // Đổi xong thì đóng form này lại
                    }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Lỗi kết nối CSDL: " + ex.Message, "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
    }
}