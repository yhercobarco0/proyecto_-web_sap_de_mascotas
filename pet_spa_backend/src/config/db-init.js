const bcrypt = require('bcrypt');
const speakeasy = require('speakeasy');
const pool = require('./db.js');

const initializeDatabase = async () => {
  try {
    await pool.query(`ALTER TABLE CLIENTES ADD COLUMN IF NOT EXISTS ci VARCHAR(50);`);
    await pool.query(`
      CREATE TABLE IF NOT EXISTS USUARIO_SEGURIDAD (
        id_seguridad SERIAL PRIMARY KEY,
        id_usuario INT UNIQUE REFERENCES USUARIOS(id_usuario) ON DELETE CASCADE,
        failed_attempts INT NOT NULL DEFAULT 0,
        locked_until TIMESTAMP,
        twofa_enabled BOOLEAN NOT NULL DEFAULT false,
        twofa_secret TEXT,
        last_activity TIMESTAMP
      );
    `);

    await pool.query(`
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
    `);

    await pool.query(`
      INSERT INTO ROLES (nombre, description) VALUES
        ('Administrador','Acceso total al sistema'),
        ('Recepción','Personal de atención al cliente y agendamiento'),
        ('Groomers','Personal encargado del spa de mascotas'),
        ('Clientes','Dueño de mascota registrado en el sistema')
      ON CONFLICT (nombre) DO NOTHING;
    `);

    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;
    const adminName = process.env.ADMIN_NAME || 'Administrador PetSpa';
    if (adminEmail && adminPassword) {
      const existing = await pool.query('SELECT * FROM USUARIOS WHERE UPPER(email) = UPPER($1)', [adminEmail]);
      if (existing.rows.length === 0) {
        const roleRes = await pool.query('SELECT id_rol FROM ROLES WHERE nombre = $1', ['Administrador']);
        const idRol = roleRes.rows[0]?.id_rol;
        const hashedPassword = await bcrypt.hash(adminPassword, 10);
        const userRes = await pool.query(
          `INSERT INTO USUARIOS (id_rol, nombre, email, password_hash, estado)
           VALUES ($1, $2, $3, $4, 'activo') RETURNING id_usuario`,
          [idRol, adminName, adminEmail, hashedPassword]
        );
        const userId = userRes.rows[0].id_usuario;
        const secret = speakeasy.generateSecret({ name: `PetSpa Admin (${adminEmail})` });

        await pool.query(
          `INSERT INTO USUARIO_SEGURIDAD (id_usuario, twofa_enabled, twofa_secret)
           VALUES ($1, true, $2)`,
          [userId, secret.base32]
        );

        console.log(`✅ Usuario administrador seed creado: ${adminEmail}`);
        console.log(`🔐 Admin 2FA secret: ${secret.base32}`);
        console.log(`🔗 Admin 2FA URL: ${secret.otpauth_url}`);
      } else {
        const userId = existing.rows[0].id_usuario;
        const secRes = await pool.query('SELECT twofa_secret FROM USUARIO_SEGURIDAD WHERE id_usuario = $1', [userId]);
        const secret = secRes.rows[0]?.twofa_secret;
        if (secret) {
          const secretUri = `otpauth://totp/PetSpa%20Admin%20(${encodeURIComponent(adminEmail)})?secret=${secret}&issuer=PetSpa`;
          console.log(`✅ Usuario administrador existente: ${adminEmail}`);
          console.log(`🔐 Admin 2FA secret (existente): ${secret}`);
          console.log(`🔗 Admin 2FA URL (existente): ${secretUri}`);
        } else {
          const newSecret = speakeasy.generateSecret({ name: `PetSpa Admin (${adminEmail})` });
          await pool.query(
            `UPDATE USUARIO_SEGURIDAD SET twofa_enabled = true, twofa_secret = $1 WHERE id_usuario = $2`,
            [newSecret.base32, userId]
          );
          console.log(`✅ Usuario administrador existente sin 2FA, se creó nuevo secret.`);
          console.log(`🔐 Admin 2FA secret: ${newSecret.base32}`);
          console.log(`🔗 Admin 2FA URL: ${newSecret.otpauth_url}`);
        }
      }
    }

    console.log('✅ Esquema de autenticación inicializado correctamente.');
  } catch (error) {
    console.error('❌ Error al inicializar el esquema de autenticación:', error.message);
  }
};

module.exports = { initializeDatabase };