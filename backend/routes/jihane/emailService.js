import dotenv from 'dotenv';
dotenv.config();

const MAIL_API = 'https://pahae-utils.vercel.app/api/mail';
const BASE_URL = process.env.SERVER;

const sendMail = async (toEmail, subject, html) => {
  const url = new URL(MAIL_API);
  url.searchParams.set('email', toEmail);
  url.searchParams.set('subject', subject);
  url.searchParams.set('text', subject);
  url.searchParams.set('html', html);

  const response = await fetch(url.toString());
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Mail API error ${response.status}: ${text}`);
  }
  console.log(`Email sent to ${toEmail}`);
};

const sendPasswordResetEmail = async (toEmail, userName, role = 'client') => {
  const segment = role === 'coach' ? 'coaches' : 'auth';
  const resetUrl = `${BASE_URL}/api/jihane/${segment}/reset-password?email=${encodeURIComponent(toEmail)}`;

  const html = `
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
          You requested a password reset.<br>
          Click the button below to create a new password.
        </div>
        <a href="${resetUrl}" class="btn">RESET MY PASSWORD →</a>
        <div class="note">
          If you did not request this, please ignore this email.<br>
          Link: <span style="color:#A3FF12;word-break:break-all">${resetUrl}</span>
        </div>
      </div>
      <div class="footer">© 2025 GymFuel · All rights reserved</div>
    </div>
    </body></html>
  `;

  await sendMail(toEmail, 'GymFuel – Password Reset', html);
};

// ── HTML Pages ──────────────────────────────────────────────

const htmlError = (title, message) => `
  <html><body style="background:#0A0A0A;color:#fff;font-family:Arial;display:flex;align-items:center;justify-content:center;height:100vh;margin:0">
    <div style="text-align:center">
      <h2 style="color:#FF4444">❌ ${title}</h2>
      <p style="color:#888;margin-top:8px">${message}</p>
    </div>
  </body></html>
`;

const htmlResetForm = (email, postUrl) => `
  <!DOCTYPE html><html><head><meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1.0">
  <title>GymFuel – Password Reset</title>
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
      <h2>New Password</h2>
      <p>Choose a password with at least 6 characters.</p>
      <div class="error" id="error-msg"></div>
      <label>NEW PASSWORD</label>
      <input type="password" id="password" placeholder="New password"/>
      <label>CONFIRM PASSWORD</label>
      <input type="password" id="confirm" placeholder="Confirm password"/>
      <button onclick="submitReset()">RESET →</button>
    </div>
    <div class="success-box" id="success-box">
      <h2>✅ Password successfully reset!</h2>
      <p>You can now log in with your new password.</p>
    </div>
  </div>
  <script>
    async function submitReset() {
      const password = document.getElementById('password').value;
      const confirm  = document.getElementById('confirm').value;
      const errorMsg = document.getElementById('error-msg');
      errorMsg.style.display = 'none';

      if (password.length < 6) {
        errorMsg.textContent = 'At least 6 characters.';
        errorMsg.style.display = 'block';
        return;
      }

      if (password !== confirm) {
        errorMsg.textContent = 'Passwords do not match.';
        errorMsg.style.display = 'block';
        return;
      }

      try {
        const response = await fetch('${postUrl}', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: '${email}', newPassword: password }),
        });

        const data = await response.json();

        if (data.success) {
          document.getElementById('form-box').style.display = 'none';
          document.getElementById('success-box').style.display = 'block';
        } else {
          errorMsg.textContent = data.message || 'Error.';
          errorMsg.style.display = 'block';
        }
      } catch(e) {
        errorMsg.textContent = 'Error: ' + e;
        errorMsg.style.display = 'block';
      }
    }
  </script>
  </body></html>
`;

export { sendPasswordResetEmail, htmlError, htmlResetForm };