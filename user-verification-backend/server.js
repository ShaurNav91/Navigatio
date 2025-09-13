const express = require('express');
const cors = require('cors');
const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.post('/verify-user', (req, res) => {
  const { name, email, phone } = req.body;
  console.log(req.body);
  if (name === 'Sonima Mishra' && email === 'sonima@gmail.com' && phone === '+11234567890') {
    return res.json({ valid: true });
  }

  res.json({ valid: false });
});

app.listen(port, () => {
  console.log(`✅ Server running at http://10.0.2.2:${port}`);
});


const nodemailer = require('nodemailer');

// Configure transporter (example with Gmail SMTP)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'sonima@gmail.com',
    pass: 'dlml taeg ahrx dzwg', // Use Gmail App Password (not your real password)
  },
});

app.post('/send-email-otp', async (req, res) => {
  const { email, otp } = req.body;
  try {
    await transporter.sendMail({
      from: '"Navigatio" <sonima@gmail.com>',
      to: email,
      subject: 'Your OTP Code',
      text: `Your OTP code is: ${otp}`,
    });
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: error.message });
  }
});
