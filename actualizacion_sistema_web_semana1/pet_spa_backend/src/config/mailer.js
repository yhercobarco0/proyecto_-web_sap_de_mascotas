const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.MAIL_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.MAIL_PORT || '587', 10),
  secure: process.env.MAIL_SECURE === 'true',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
  tls: {
    rejectUnauthorized: false
  }
});

exports.sendMail = async ({ to, subject, text, html }) => {
  const mailOptions = {
    from: process.env.MAIL_FROM || process.env.MAIL_USER || 'petspa@example.com',
    to,
    subject,
    text,
    html,
  };
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log(`[MAILER] Email sent successfully to ${to}. MessageId: ${info.messageId}`);
    return { success: true, info };
  } catch (error) {
    console.error(`[MAILER ERROR] Failed to send email to ${to}:`, error);
    return { success: false, error };
  }
};
