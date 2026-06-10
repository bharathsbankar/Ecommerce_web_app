CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);

-- Seed initial admin user: admin@gmail.com / qwerty
-- The hash is Django bcrypt format: bcrypt$$2b$12$D2Mee1k33j06/kF4V0L87.oV5c2W/yYJk.HuxYlI7L27hCugC0M9W
INSERT INTO users (email, username, password, role) VALUES
('admin@gmail.com', 'admin', 'bcrypt$$2b$12$D2Mee1k33j06/kF4V0L87.oV5c2W/yYJk.HuxYlI7L27hCugC0M9W', 'admin')
ON DUPLICATE KEY UPDATE id=id;
