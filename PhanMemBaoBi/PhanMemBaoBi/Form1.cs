using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;
namespace PhanMemBaoBi
{
    public partial class INVARIX : Form
    {
        public INVARIX()
        {
            InitializeComponent();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }

        private void label2_Click(object sender, EventArgs e)
        {

        }

        private void Form1_Load(object sender, EventArgs e)
        {
            
        }
        private void btnLogin_Click(object sender, EventArgs e)
        {
            try
            {
                if (string.IsNullOrEmpty(txtUser.Text) || string.IsNullOrEmpty(txtPass.Text))
                {
                    MessageBox.Show("Vui lòng nhập tài khoản và mật khẩu!");
                    return;
                }
                string connString = @"Data Source=(localdb)\MSSQLLocalDB;Initial Catalog=QuanLyBaoBi;Integrated Security=True";

                using (SqlConnection conn = new SqlConnection(connString))
                {
                    conn.Open();
                    string sql = "SELECT * FROM NguoiDung WHERE TaiKhoan=@user AND MatKhau=@pass";
                    SqlCommand cmd = new SqlCommand(sql, conn);
                    cmd.Parameters.AddWithValue("@user", txtUser.Text);
                    cmd.Parameters.AddWithValue("@pass", txtPass.Text);

                    SqlDataAdapter adapter = new SqlDataAdapter(cmd);
                    DataTable dt = new DataTable();
                    adapter.Fill(dt);

                    if (dt.Rows.Count > 0)
                    {
                        FormDashboard f = new FormDashboard();
                        this.Hide();
                        f.ShowDialog();
                        this.Close();
                    }
                    else
                    {
                        MessageBox.Show("Tài khoản hoặc mật khẩu không chính xác!");
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi kết nối: " + ex.Message);
            }
        }
    }
}
