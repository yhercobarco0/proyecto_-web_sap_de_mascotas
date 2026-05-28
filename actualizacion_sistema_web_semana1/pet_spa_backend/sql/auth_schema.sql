-- Script de inicialización de soporte de autenticación y seguridad para Pet Spa

ALTER TABLE CLIENTES ADD COLUMN IF NOT EXISTS ci VARCHAR(50);
ALTER TABLE TRABAJADORES ADD COLUMN IF NOT EXISTS turno VARCHAR(50);
ALTER TABLE TRABAJADORES ADD COLUMN IF NOT EXISTS especialidad VARCHAR(100);
ALTER TABLE TRABAJADORES ADD COLUMN IF NOT EXISTS telefono VARCHAR(20);

CREATE TABLE IF NOT EXISTS USUARIO_SEGURIDAD (
    id_seguridad SERIAL PRIMARY KEY,
    id_usuario INT UNIQUE REFERENCES USUARIOS(id_usuario) ON DELETE CASCADE,
    failed_attempts INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMP,
    twofa_enabled BOOLEAN NOT NULL DEFAULT false,
    twofa_secret TEXT,
    last_activity TIMESTAMP
);

CREATE TABLE IF NOT EXISTS AUDIT_LOGS (
    id_log SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES USUARIOS(id_usuario) ON DELETE SET NULL,
    rol VARCHAR(256),
    ip_address VARCHAR(100),
    browser TEXT,
    action VARCHAR(256),
    details JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO ROLES (nombre, description) VALUES
 ('ADMINISTRADOR','Acceso total al sistema'),
 ('RECEPCION','Personal de recepción'),
 ('GROOMER','Groomer o personal de servicio'),
 ('CLIENTE','Dueño de mascota')
ON CONFLICT (nombre) DO NOTHING;
