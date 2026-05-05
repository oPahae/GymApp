// const nodemailer = require('nodemailer');

// const transporter = nodemailer.createTransport({
//   host: process.env.EMAIL_HOST,
//   port: process.env.EMAIL_PORT,
//   secure: false,
//   auth: {
//     user: process.env.EMAIL_USER,
//     pass: process.env.EMAIL_PASS,
//   },
// });

// /**
//  * Envoie un email de réinitialisation de mot de passe
//  * @param {string} toEmail - Email du destinataire
//  * @param {string} resetToken - Token de réinitialisation
//  * @param {string} userName - Nom de l'utilisateur
//  */
// const sendPasswordResetEmail = async (toEmail, resetToken, userName) => {
//   const resetUrl = `${process.env.FRONTEND_URL}/reset-password?token=${resetToken}`;

//   const mailOptions = {
//     from: process.env.EMAIL_FROM,
//     to: toEmail,
//     subject: 'GymFuel – Réinitialisation de mot de passe',
//     html: `
//       <!DOCTYPE html>
//       <html>
//       <head>
//         <meta charset="UTF-8">
//         <style>
//           body { font-family: Arial, sans-serif; background: #0A0A0A; color: #fff; margin: 0; padding: 0; }
//           .container { max-width: 520px; margin: 40px auto; background: #141414; border-radius: 16px; overflow: hidden; border: 1px solid rgba(255,255,255,0.06); }
//           .header { background: #0A0A0A; padding: 32px; text-align: center; border-bottom: 1px solid rgba(255,255,255,0.06); }
//           .logo { color: #A3FF12; font-size: 22px; font-weight: 900; letter-spacing: 5px; }
//           .body { padding: 36px 32px; }
//           .title { font-size: 24px; font-weight: 900; margin-bottom: 12px; }
//           .subtitle { color: #888; font-size: 14px; line-height: 1.6; margin-bottom: 28px; }
//           .btn { display: inline-block; background: #A3FF12; color: #0A0A0A; text-decoration: none; font-weight: 900; font-size: 14px; letter-spacing: 2px; padding: 16px 32px; border-radius: 12px; }
//           .note { margin-top: 24px; color: #555; font-size: 12px; line-height: 1.6; }
//           .footer { padding: 20px 32px; text-align: center; color: #444; font-size: 11px; border-top: 1px solid rgba(255,255,255,0.04); }
//         </style>
//       </head>
//       <body>
//         <div class="container">
//           <div class="header">
//             <div class="logo">GYMFUEL</div>
//           </div>
//           <div class="body">
//             <div class="title">Hey ${userName} </div>
//             <div class="subtitle">
//               Vous avez demandé une réinitialisation de votre mot de passe.<br>
//               Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe.<br>
//               Ce lien expire dans <strong>1 heure</strong>.
//             </div>
//             <a href="${resetUrl}" class="btn">RÉINITIALISER MON MOT DE PASSE →</a>
//             <div class="note">
//               Si vous n'avez pas fait cette demande, ignorez cet email.<br>
//               Votre mot de passe restera inchangé.<br><br>
//               Ou copiez ce lien dans votre navigateur :<br>
//               <span style="color:#A3FF12; word-break: break-all;">${resetUrl}</span>
//             </div>
//           </div>
//           <div class="footer">© 2025 GymFuel · Tous droits réservés</div>
//         </div>
//       </body>
//       </html>
//     `,
//   };

//   await transporter.sendMail(mailOptions);
// };

// module.exports = { sendPasswordResetEmail };