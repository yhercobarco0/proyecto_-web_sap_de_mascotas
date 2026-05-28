const nodemailer = require('nodemailer');

const createTransporter = () => {
  if (!process.env.MAIL_USER || !process.env.MAIL_PASS || !process.env.MAIL_HOST) {
    throw new Error('Configuración de email incompleta. Define MAIL_USER, MAIL_PASS, MAIL_HOST en .env');
  }

  return nodemailer.createTransporter({
    host: process.env.MAIL_HOST,
    port: Number(process.env.MAIL_PORT || 587),
    secure: process.env.MAIL_SECURE === 'true',
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS,
    },
  });
};

const sendActivationEmail = async ({ email, nombre, activationLink }) => {
  const transporter = createTransporter();
  const subject = 'Activa tu cuenta Pet Spa';
  const html = `
    <p>Hola <strong>${nombre}</strong>,</p>
    <p>Para completar tu registro, haz clic en este enlace dentro de los próximos 15 minutos:</p>
    <p><a href="${activationLink}">${activationLink}</a></p>
    <p>Si no hiciste esta solicitud, ignora este correo.</p>
  `;

  await transporter.sendMail({
    from: process.env.MAIL_FROM || process.env.MAIL_USER,
    to: email,
    subject,
    html,
  });
};

module.exports = { sendActivationEmail };