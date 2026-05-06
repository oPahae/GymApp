import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

const BREVO_USER = process.env.BREVO_USER;
const BREVO_PASS = process.env.BREVO_PASS;
const FROM_EMAIL = process.env.FROM_EMAIL;

const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com',
  port: 587,
  secure: false,
  auth: { user: BREVO_USER, pass: BREVO_PASS },
});

transporter.verify((error) => {
  if (error) console.error('❌ Brevo SMTP error:', error);
  else console.log('✅ Brevo SMTP ready');
});

// role = 'client' | 'coach'
const sendPasswordResetEmail = async (toEmail, resetToken, userName, role = 'client') => {
  const resetUrl = `http://localhost:5000/api/jihane/${role === 'coach' ? 'coaches' : 'auth'}/reset-password?token=${resetToken}`;

  await transporter.sendMail({
    from: `"GymFuel" <${FROM_EMAIL}>`,
    to: toEmail,
    subject: 'GymFuel – Réinitialisation de mot de passe',
    html: `
      <!DOCTYPE html><html><head><meta charset="UTF-8">
      <style>
        body{font-family:Arial,sans-serif;background:#0A0A0A;color:#fff;margin:0;padding:0}
        .container{max-width:520px;margin:40px auto;background:#141414;border-radius:16px;overflow:hidden;border:1px solid rgba(255,255,255,0.06)}
        .header{background:#0A0A0A;padding:32px;text-align:center;border-bottom:1px solid rgba(255,255,255,0.06)}
        .logo{color:#A3FF12;font-size:22px;font-weight:900;letter-spacing:5px}
        .body{padding:36px 32px}
        .title{font-size:24px;font-weight:900;margin-bottom:12px}
        .subtitle{color:#888;font-size:14px;line-height:1.6;margin-bottom:28px}
        .btn{display:inline-block;background:#A3FF12;color:#0A0A0A;text-decoration:none;font-weight:900;font-size:14px;letter-spacing:2px;padding:16px 32px;border-radius:12px}
        .note{margin-top:24px;color:#555;font-size:12px;line-height:1.6}
        .footer{padding:20px 32px;text-align:center;color:#444;font-size:11px;border-top:1px solid rgba(255,255,255,0.04)}
      </style></head><body>
      <div class="container">
        <div class="header"><div class="logo">GYMFUEL</div></div>
        <div class="body">
          <div class="title">Hey ${userName} 💪</div>
          <div class="subtitle">
            Vous avez demandé une réinitialisation de votre mot de passe.<br>
            Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe.<br>
            Ce lien expire dans <strong>1 heure</strong>.
          </div>
          <a href="${resetUrl}" class="btn">RÉINITIALISER MON MOT DE PASSE →</a>
          <div class="note">
            Si vous n'avez pas fait cette demande, ignorez cet email.<br>
            Lien : <span style="color:#A3FF12;word-break:break-all">${resetUrl}</span>
          </div>
        </div>
        <div class="footer">© 2025 GymFuel · Tous droits réservés</div>
      </div>
      </body></html>
    `,
  });
};

// ── Fonctions HTML partagées ──────────────────
const htmlError = (title, message) => `
  <html><body style="background:#0A0A0A;color:#fff;font-family:Arial;display:flex;align-items:center;justify-content:center;height:100vh;margin:0">
    <div style="text-align:center">
      <h2 style="color:#FF4444">❌ ${title}</h2>
      <p style="color:#888;margin-top:8px">${message}</p>
    </div>
  </body></html>
`;

const htmlResetForm = (token, postUrl) => `
  <!DOCTYPE html><html><head><meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>GymFuel – Réinitialisation</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{background:#0A0A0A;color:#fff;font-family:Arial,sans-serif;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:20px}
    .container{background:#141414;border-radius:16px;border:1px solid rgba(255,255,255,0.06);padding:40px 32px;width:100%;max-width:420px}
    .logo{color:#A3FF12;font-size:22px;font-weight:900;letter-spacing:5px;text-align:center;margin-bottom:32px}
    h2{font-size:24px;font-weight:900;margin-bottom:8px}
    p{color:#888;font-size:14px;margin-bottom:28px}
    label{display:block;color:#888;font-size:11px;font-weight:700;letter-spacing:1.2px;margin-bottom:7px}
    input{width:100%;height:52px;background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.10);border-radius:14px;color:#fff;font-size:14px;padding:0 16px;margin-bottom:16px;outline:none}
    input:focus{border-color:rgba(163,255,18,0.5)}
    button{width:100%;height:52px;background:#A3FF12;color:#0A0A0A;border:none;border-radius:14px;font-size:16px;font-weight:900;letter-spacing:2px;cursor:pointer;margin-top:8px}
    button:hover{background:#8FE010}
    .error{color:#FF4444;font-size:13px;margin-bottom:12px;display:none}
    .success-box{text-align:center;display:none}
    .success-box h2{color:#A3FF12;margin-bottom:12px}
  </style></head><body>
  <div class="container">
    <div class="logo">GYMFUEL</div>
    <div id="form-box">
      <h2>Nouveau mot de passe</h2>
      <p>Choisissez un mot de passe d'au moins 6 caractères.</p>
      <div class="error" id="error-msg"></div>
      <label>NOUVEAU MOT DE PASSE</label>
      <input type="password" id="password" placeholder="Nouveau mot de passe"/>
      <label>CONFIRMER LE MOT DE PASSE</label>
      <input type="password" id="confirm" placeholder="Confirmer le mot de passe"/>
      <button onclick="submitReset()">RÉINITIALISER →</button>
    </div>
    <div class="success-box" id="success-box">
      <h2>✅ Mot de passe réinitialisé !</h2>
      <p>Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.</p>
    </div>
  </div>
  <script>
    async function submitReset() {
      const password = document.getElementById('password').value;
      const confirm = document.getElementById('confirm').value;
      const errorMsg = document.getElementById('error-msg');
      errorMsg.style.display = 'none';
      if (password.length < 6) { errorMsg.textContent = 'Au moins 6 caractères.'; errorMsg.style.display = 'block'; return; }
      if (password !== confirm) { errorMsg.textContent = 'Les mots de passe ne correspondent pas.'; errorMsg.style.display = 'block'; return; }
      try {
        const response = await fetch('${postUrl}', {
          method: 'POST',
          headers: {'Content-Type':'application/json'},
          body: JSON.stringify({ token: '${token}', newPassword: password }),
        });
        const data = await response.json();
        if (data.success) {
          document.getElementById('form-box').style.display = 'none';
          document.getElementById('success-box').style.display = 'block';
        } else {
          errorMsg.textContent = data.message || 'Erreur.';
          errorMsg.style.display = 'block';
        }
      } catch(e) { errorMsg.textContent = 'Erreur réseau.'; errorMsg.style.display = 'block'; }
    }
  </script>
  </body></html>
`;

export { sendPasswordResetEmail, htmlError, htmlResetForm };