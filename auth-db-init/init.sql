CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'customer',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);

-- Seed initial admin user: admin@gmail.com / admin
-- The hash is Django bcrypt format for 'admin': bcrypt_sha256$$2b$12$Hym1qKVJBQUMeCzMqSWJHO.bmOKDbCngUBarigs0B38ymG.8A8n7a
INSERT INTO users (email, username, password, role) VALUES
('admin@gmail.com', 'admin', 'bcrypt_sha256$$2b$12$Hym1qKVJBQUMeCzMqSWJHO.bmOKDbCngUBarigs0B38ymG.8A8n7a', 'admin')
ON DUPLICATE KEY UPDATE password='bcrypt_sha256$$2b$12$Hym1qKVJBQUMeCzMqSWJHO.bmOKDbCngUBarigs0B38ymG.8A8n7a', role='admin';
