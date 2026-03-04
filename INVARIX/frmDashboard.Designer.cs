namespace INVARIX
{
    partial class frmDashboard
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.hệThốngToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.menuDoiMatKhau = new System.Windows.Forms.ToolStripMenuItem();
            this.menuDangXuat = new System.Windows.Forms.ToolStripMenuItem();
            this.danhMụcToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.kinhDoanhToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.menuTinhGia = new System.Windows.Forms.ToolStripMenuItem();
            this.sảnXuấtToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.khoToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.kếToánToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.menuStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // menuStrip1
            // 
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.hệThốngToolStripMenuItem,
            this.danhMụcToolStripMenuItem,
            this.kinhDoanhToolStripMenuItem,
            this.sảnXuấtToolStripMenuItem,
            this.khoToolStripMenuItem,
            this.kếToánToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(800, 24);
            this.menuStrip1.TabIndex = 0;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // hệThốngToolStripMenuItem
            // 
            this.hệThốngToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.menuDoiMatKhau,
            this.menuDangXuat});
            this.hệThốngToolStripMenuItem.Name = "hệThốngToolStripMenuItem";
            this.hệThốngToolStripMenuItem.Size = new System.Drawing.Size(69, 20);
            this.hệThốngToolStripMenuItem.Text = "Hệ thống";
            // 
            // menuDoiMatKhau
            // 
            this.menuDoiMatKhau.Name = "menuDoiMatKhau";
            this.menuDoiMatKhau.Size = new System.Drawing.Size(145, 22);
            this.menuDoiMatKhau.Text = "Đổi mật khẩu";
            this.menuDoiMatKhau.Click += new System.EventHandler(this.menuDoiMatKhau_Click);
            // 
            // menuDangXuat
            // 
            this.menuDangXuat.Name = "menuDangXuat";
            this.menuDangXuat.Size = new System.Drawing.Size(145, 22);
            this.menuDangXuat.Text = "Đăng xuất";
            this.menuDangXuat.Click += new System.EventHandler(this.menuDangXuat_Click);
            // 
            // danhMụcToolStripMenuItem
            // 
            this.danhMụcToolStripMenuItem.Name = "danhMụcToolStripMenuItem";
            this.danhMụcToolStripMenuItem.Size = new System.Drawing.Size(74, 20);
            this.danhMụcToolStripMenuItem.Text = "Danh mục";
            // 
            // kinhDoanhToolStripMenuItem
            // 
            this.kinhDoanhToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.menuTinhGia});
            this.kinhDoanhToolStripMenuItem.Name = "kinhDoanhToolStripMenuItem";
            this.kinhDoanhToolStripMenuItem.Size = new System.Drawing.Size(80, 20);
            this.kinhDoanhToolStripMenuItem.Text = "Kinh doanh";
            // 
            // menuTinhGia
            // 
            this.menuTinhGia.Name = "menuTinhGia";
            this.menuTinhGia.Size = new System.Drawing.Size(180, 22);
            this.menuTinhGia.Text = "Tính giá & Báo giá";
            this.menuTinhGia.Click += new System.EventHandler(this.menuTinhGia_Click);
            // 
            // sảnXuấtToolStripMenuItem
            // 
            this.sảnXuấtToolStripMenuItem.Name = "sảnXuấtToolStripMenuItem";
            this.sảnXuấtToolStripMenuItem.Size = new System.Drawing.Size(63, 20);
            this.sảnXuấtToolStripMenuItem.Text = "Sản xuất";
            // 
            // khoToolStripMenuItem
            // 
            this.khoToolStripMenuItem.Name = "khoToolStripMenuItem";
            this.khoToolStripMenuItem.Size = new System.Drawing.Size(40, 20);
            this.khoToolStripMenuItem.Text = "Kho";
            // 
            // kếToánToolStripMenuItem
            // 
            this.kếToánToolStripMenuItem.Name = "kếToánToolStripMenuItem";
            this.kếToánToolStripMenuItem.Size = new System.Drawing.Size(59, 20);
            this.kếToánToolStripMenuItem.Text = "Kế toán";
            // 
            // frmDashboard
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 450);
            this.Controls.Add(this.menuStrip1);
            this.MainMenuStrip = this.menuStrip1;
            this.Name = "frmDashboard";
            this.Text = "frmDashboard";
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem hệThốngToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem menuDoiMatKhau;
        private System.Windows.Forms.ToolStripMenuItem menuDangXuat;
        private System.Windows.Forms.ToolStripMenuItem danhMụcToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem kinhDoanhToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem menuTinhGia;
        private System.Windows.Forms.ToolStripMenuItem sảnXuấtToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem khoToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem kếToánToolStripMenuItem;
    }
}