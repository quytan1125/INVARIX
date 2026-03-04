-- 1. Tạo cơ sở dữ liệu
CREATE DATABASE BaoBiERP;
GO

USE BaoBiERP;
GO

-- 2. Tạo bảng Người dùng (Users)
CREATE TABLE Users (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Username VARCHAR(50) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName NVARCHAR(100),
    Role NVARCHAR(50) -- Phân quyền: Admin, KeToan, KinhDoanh, Kho [cite: 1134, 1144, 1159, 1171]
);
GO

-- 3. Tạo một tài khoản Admin mẫu để đăng nhập thử (Mật khẩu tạm là: admin123)
-- Lưu ý: Trong thực tế sau này, chúng ta sẽ mã hóa mật khẩu thay vì để chữ thường.
INSERT INTO Users (Username, PasswordHash, FullName, Role)
VALUES ('admin', 'admin123', N'Quản trị viên hệ thống', 'Admin');
GO