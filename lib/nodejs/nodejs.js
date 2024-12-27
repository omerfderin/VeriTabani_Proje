const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const bodyParser = require('body-parser');

const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(express.urlencoded({ extended: true }));

const port = 3000;

//Veri tabanına bağlantı sağlama (Bağlantı limiti de eklendi)
const connection = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'OD_22111971',
  database: 'veritabani',
  waitForConnections: true,
  connectionLimit: 4,
  queueLimit: 0
});

// Projeleri gecikme süreleriyle birlikte getirme
app.get('/projects', (req, res) => {
  const query = `
    SELECT 
      p.*,
      COUNT(DISTINCT g.gID) as totalTasks,
      SUM(g.gDurum = 'Tamamlandı') as completedTasks,
      COALESCE(
        MAX(
          CASE 
            WHEN g.gDurum != 'Tamamlandı' AND CURDATE() > g.gBitisTarih 
            THEN DATEDIFF(CURDATE(), g.gBitisTarih)
            ELSE 0 
          END
        ), 0
      ) as totalDelay
    FROM Proje p
    LEFT JOIN Gorev g ON p.pID = g.Proje_pID
    GROUP BY p.pID
    ORDER BY p.pID DESC
  `;
  
  connection.query(query, (error, results) => {
    if (error) {
      console.error('MySQL sorgu hatası:', error);
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    // Her projenin bitiş tarihini gecikme süresi kadar güncelle
    const projectsWithDelays = results.map(project => {
      const originalEndDate = new Date(project.pBitisTarih);
      const totalDelay = parseInt(project.totalDelay) || 0;
      const adjustedEndDate = new Date(originalEndDate.setDate(originalEndDate.getDate() + totalDelay));
      
      return {
        ...project,
        pBitisTarih: adjustedEndDate.toISOString().split('T')[0],
        originalEndDate: project.pBitisTarih,
        totalDelay: totalDelay
      };
    });

    res.json(projectsWithDelays);
  });
});

// Yeni proje ekleme işlemi
app.post('/projects', (req, res) => {
  console.log('Gelen veri:', req.body);
  
  const { pAd, pBaslaTarih, pBitisTarih, Kullanici_kID } = req.body;
  
  if (!pAd || !pBaslaTarih || !pBitisTarih || !Kullanici_kID) {
    return res.status(400).json({
      error: 'Gerekli alanlar eksik',
      details: {
        pAd: !pAd ? 'Proje adı gerekli' : null,
        pBaslaTarih: !pBaslaTarih ? 'Başlangıç tarihi gerekli' : null,
        pBitisTarih: !pBitisTarih ? 'Bitiş tarihi gerekli' : null,
        Kullanici_kID: !Kullanici_kID ? 'Kullanıcı ID gerekli' : null
      }
    });
  }

  if (pAd.length > 25) {
    return res.status(400).json({
      error: 'Geçersiz veri',
      details: 'Proje adı 25 karakterden uzun olamaz'
    });
  }

  const now = new Date();
  const startDate = new Date(pBaslaTarih);
  const endDate = new Date(pBitisTarih);
  
  if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
    return res.status(400).json({ 
      error: 'Geçersiz tarih formatı',
      details: 'Tarihler YYYY-MM-DD formatında olmalıdır'
    });
  }
  
  if (endDate < startDate) {
    return res.status(400).json({ 
      error: 'Geçersiz tarih aralığı',
      details: 'Bitiş tarihi başlangıç tarihinden önce olamaz'
    });
  }

  // Projenin başlangıç durumunu belirle
  let pDurum = 'Tamamlanacak';
  if (startDate <= now && now <= endDate) {
    pDurum = 'Devam Ediyor';
  }
  else if (now > endDate) {
    pDurum = 'Tamamlandı'
  }

  const checkUserQuery = 'SELECT kID FROM kullanici WHERE kID = ?';
  connection.query(checkUserQuery, [Kullanici_kID], (error, results) => {
    if (error) {
      console.error('MySQL kullanıcı kontrol hatası:', error);
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    if (results.length === 0) {
      return res.status(400).json({
        error: 'Geçersiz kullanıcı',
        details: 'Belirtilen kullanıcı ID bulunamadı'
      });
    }

    const insertQuery = 'INSERT INTO proje (pAd, pBaslaTarih, pBitisTarih, Kullanici_kID) VALUES (?, ?, ?, ?)';
    const values = [pAd, pBaslaTarih, pBitisTarih, Kullanici_kID];

    connection.query(insertQuery, values, (error, results) => {
      if (error) {
        console.error('MySQL ekleme hatası:', error);
        return res.status(500).json({ 
          error: 'Veritabanı hatası',
          details: error.message 
        });
      }
      
      res.status(201).json({
        message: 'Proje başarıyla eklendi',
        projectId: results.insertId
      });
    });
  });
});

// Proje bitiş tarihini güncelleme
app.put('/projects/:id/update-end-date', (req, res) => {
  const projectId = req.params.id;
  const { newEndDate } = req.body;

  const query = `
    UPDATE Proje 
    SET pBitisTarih = ?
    WHERE pID = ?
  `;

  connection.query(query, [newEndDate, projectId], (error, result) => {
    if (error) {
      console.error('MySQL güncelleme hatası:', error);
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        error: 'Proje bulunamadı'
      });
    }

    res.json({
      message: 'Proje bitiş tarihi başarıyla güncellendi',
      projectId: projectId,
      newEndDate: newEndDate
    });
  });
});

// Görevleri getirme işlemi (Ayrıca veritabanında da güncelleme yapılıyor)
app.get('/tasks/:projectId', (req, res) => {
  const projectId = req.params.projectId;
  const query = `
    SELECT g.*, c.cAdSoyad, c.cID
    FROM Gorev g
    LEFT JOIN Calisanlar c ON g.Calisanlar_cID = c.cID
    WHERE g.Proje_pID = ?
    ORDER BY g.gBaslaTarih ASC
  `;

  connection.query(query, [projectId], (error, results) => {
    if (error) {
      console.error('MySQL sorgu hatası:', error);
      return res.status(500).json({ error: 'Veritabanı hatası' });
    }


    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const updatedResults = results.map(task => {
      const startDate = new Date(task.gBaslaTarih);
      const taskStartDate = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());

      let newStatus = task.gDurum;

      if (task.gDurum !== 'Tamamlandı') {
        if (taskStartDate > today) {
          newStatus = 'Tamamlanacak';
        } else {
          newStatus = 'Devam Ediyor';
        }

        if (newStatus !== task.gDurum) {
          const updateQuery = 'UPDATE Gorev SET gDurum = ? WHERE gID = ?';
          connection.query(updateQuery, [newStatus, task.gID], (updateError) => {
            if (updateError) {
              console.error('Durum güncelleme hatası:', updateError);
            }
          });
        }
      }

      return {
        ...task,
        gDurum: newStatus
      };
    });

    res.json(updatedResults);
  });
});

// Get tasks by employee
app.get('/tasks/employee/:employeeId', (req, res) => {
  const employeeId = req.params.employeeId;
  const query = `
    SELECT g.*, p.pAd as projeAdi
    FROM Gorev g
    JOIN Proje p ON g.Proje_pID = p.pID
    WHERE g.Calisanlar_cID = ?
    ORDER BY g.gBaslaTarih
  `;
  
  connection.query(query, [employeeId], (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

// Update task
app.put('/tasks/:id', (req, res) => {
  const taskId = req.params.id;
  const { gDurum, gecikmeGun } = req.body;

  const query = 'UPDATE Gorev SET gDurum = ?, gecikmeGun = ? WHERE gID = ?';
  
  connection.query(query, [gDurum, gecikmeGun, taskId], (err, result) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ message: 'Task updated successfully' });
  });
});



// Add new task
app.post('/tasks', (req, res) => {
  console.log('Received task data:', req.body);

  const { 
    gBaslaTarih, 
    gBitisTarih, 
    gAdamGun, 
    gDurum, 
    Calisanlar_cID, 
    Proje_pID 
  } = req.body;

  if (!gBaslaTarih || !gBitisTarih || !gAdamGun || !Calisanlar_cID || !Proje_pID) {
    return res.status(400).json({ 
      error: 'Missing required fields',
      receivedData: req.body 
    });
  }

  const query = `
    INSERT INTO Gorev 
    (gBaslaTarih, gBitisTarih, gAdamGun, gDurum, Calisanlar_cID, Proje_pID) 
    VALUES (?, ?, ?, ?, ?, ?)
  `;
  
  connection.query(
    query, 
    [gBaslaTarih, gBitisTarih, gAdamGun, gDurum || 'Tamamlanacak', Calisanlar_cID, Proje_pID],
    (err, result) => {
      if (err) {
        console.error('Database error:', err);
        res.status(500).json({ 
          error: err.message,
          sqlMessage: err.sqlMessage 
        });
        return;
      }
      res.status(201).json({ 
        message: 'Task added successfully',
        id: result.insertId 
      });
    }
  );
});

// EMPLOYEE ROUTES
// Get all employees with stats
app.get('/employees', (req, res) => {
  const query = `
    SELECT c.*, 
           COUNT(DISTINCT g.Proje_pID) as totalProjects,
           SUM(CASE WHEN g.gDurum = 'Tamamlandı' THEN 1 ELSE 0 END) as completedTasks
    FROM Calisanlar c
    LEFT JOIN Gorev g ON c.cID = g.Calisanlar_cID
    GROUP BY c.cID
  `;
  
  connection.query(query, (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

// Add new employee
app.post('/employees', (req, res) => {
  const { cAdSoyad } = req.body;

  if (!cAdSoyad) {
    return res.status(400).json({ 
      error: 'Eksik bilgi', 
      details: 'Çalışan adı gereklidir' 
    });
  }

  if (cAdSoyad.length > 50) {  // Çalışan adı için max karakter sınırı
    return res.status(400).json({
      error: 'Geçersiz veri',
      details: 'Çalışan adı 50 karakterden uzun olamaz'
    });
  }

  const insertQuery = 'INSERT INTO Calisanlar (cAdSoyad) VALUES (?)';
  connection.query(insertQuery, [cAdSoyad], (error, results) => {
    if (error) {
      console.error('MySQL ekleme hatası:', error);
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    res.status(201).json({
      message: 'Çalışan başarıyla eklendi',
      employeeId: results.insertId
    });
  });
});

app.delete('/employees/:id', (req, res) => {
  const employeeId = req.params.id;
  
  // First check if employee has any tasks
  const checkTasksQuery = 'SELECT COUNT(*) as taskCount FROM Gorev WHERE Calisanlar_cID = ?';
  
  connection.query(checkTasksQuery, [employeeId], (error, results) => {
    if (error) {
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    if (results[0].taskCount > 0) {
      return res.status(400).json({
        error: 'Çalışan silinemez',
        details: 'Çalışanın aktif görevleri bulunmaktadır'
      });
    }

    // Çalışan herhangi bir görevde yer almıyorsa silinebilir ya da görevi bitmeli
    const deleteQuery = 'DELETE FROM Calisanlar WHERE cID = ?';
    
    connection.query(deleteQuery, [employeeId], (error, result) => {
      if (error) {
        return res.status(500).json({ 
          error: 'Veritabanı hatası',
          details: error.message 
        });
      }

      if (result.affectedRows === 0) {
        return res.status(404).json({
          error: 'Çalışan bulunamadı'
        });
      }

      res.json({ message: 'Çalışan başarıyla silindi' });
    });
  });
});

// Kullanıcı ismi güncelleme
app.put('/employees/:id', (req, res) => {
  const employeeId = req.params.id;
  const { cAdSoyad } = req.body;

  if (!cAdSoyad) {
    return res.status(400).json({
      error: 'Eksik bilgi',
      details: 'Çalışan adı gereklidir'
    });
  }

  const updateQuery = 'UPDATE Calisanlar SET cAdSoyad = ? WHERE cID = ?';
  
  connection.query(updateQuery, [cAdSoyad, employeeId], (error, result) => {
    if (error) {
      return res.status(500).json({ 
        error: 'Veritabanı hatası',
        details: error.message 
      });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({
        error: 'Çalışan bulunamadı'
      });
    }

    res.json({ 
      message: 'Çalışan başarıyla güncellendi',
      employeeId: employeeId
    });
  });
});

app.put('/tasks/:taskId', async (req, res) => {
  const { taskId } = req.params;
  const { gDurum, gecikmeGun } = req.body;

  try {
    await db.query(
      'UPDATE tasks SET gDurum = ?, gecikmeGun = ? WHERE gID = ?',
      [gDurum, gecikmeGun, taskId]
    );
    res.status(200).send('Görev güncellendi');
  } catch (error) {
    console.error('Görev güncellenemedi:', error);
    res.status(500).send('Görev güncellenemedi');
  }
});

app.put('/projects/:projectId', async (req, res) => {
  const { projectId } = req.params;
  const { pBitisTarih } = req.body;

  try {
    await db.query(
      'UPDATE projects SET pBitisTarih = ? WHERE pID = ?',
      [pBitisTarih, projectId]
    );
    res.status(200).send('Proje güncellendi');
  } catch (error) {
    console.error('Proje güncellenemedi:', error);
    res.status(500).send('Proje güncellenemedi');
  }
});

// Görev silme işlemi
app.delete('/tasks/:id', (req, res) => {
  const taskId = req.params.id;
  
  const query = 'DELETE FROM Gorev WHERE gID = ?';
  
  connection.query(query, [taskId], (err, result) => {
    if (err) {
      console.error('Error deleting task:', err);
      return res.status(500).json({ 
        error: 'Database error', 
        details: err.message 
      });
    }
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ 
        error: 'Task not found' 
      });
    }
    
    res.json({ 
      message: 'Task deleted successfully',
      taskId: taskId
    });
  });
});

// Kayıt olma işlemi
app.post('/register', (req, res) => {
  const { kEmail, kSifre } = req.body;

  if (!kEmail || !kSifre) {
    return res.status(400).json({ error: 'Email ve şifre gerekli' });
  }

  const checkQuery = 'SELECT kID FROM kullanici WHERE kEmail = ?';
  connection.query(checkQuery, [kEmail], (error, results) => {
    if (error) {
      console.error('MySQL sorgu hatası:', error);
      return res.status(500).json({ error: 'Veritabanı hatası' });
    }

    if (results.length > 0) {
      return res.status(400).json({ error: 'Bu email zaten kayıtlı' });
    }

    const insertQuery = 'INSERT INTO kullanici (kEmail, kSifre) VALUES (?, ?)';
    connection.query(insertQuery, [kEmail, kSifre], (error, results) => {
      if (error) {
        console.error('MySQL ekleme hatası:', error);
        return res.status(500).json({ error: 'Veritabanı hatası' });
      }

      res.status(201).json({
        message: 'Kullanıcı başarıyla kaydedildi',
        userId: results.insertId,
      });
    });
  });
});

// Giriş işlemi
app.post('/login', (req, res) => {
  const { kEmail, kSifre } = req.body;

  if (!kEmail || !kSifre) {
    return res.status(400).json({ error: 'Email ve şifre gerekli' });
  }

  const query = 'SELECT kID, kEmail FROM kullanici WHERE kEmail = ? AND kSifre = ?';
  
  connection.query(query, [kEmail, kSifre], (error, results) => {
    if (error) {
      console.error('MySQL sorgu hatası:', error);
      return res.status(500).json({ error: 'Veritabanı hatası' });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: 'Geçersiz email veya şifre' });
    }

    res.json({
      kID: results[0].kID,
      kEmail: results[0].kEmail
    });
  });
});

app.put('/tasks/:id/status', (req, res) => {
  const taskId = req.params.id;
  const { gDurum } = req.body;

  // Durum validasyonu
  const validStatuses = ['Tamamlanacak', 'Devam Ediyor', 'Tamamlandı'];
  if (!validStatuses.includes(gDurum)) {
    return res.status(400).json({ 
      error: 'Geçersiz durum',
      details: 'Geçerli durumlar: ' + validStatuses.join(', ')
    });
  }

  const query = `
    UPDATE Gorev g
    SET g.gDurum = ?
    WHERE g.gID = ?`;
  
  connection.query(query, [gDurum, taskId], (err, result) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json({ 
      message: 'Görev durumu başarıyla güncellendi',
      status: gDurum
    });
  });
});

const updateTaskStatuses = () => {
  const query = `
    UPDATE Gorev g
    SET g.gDurum = CASE
      WHEN CURDATE() < g.gBaslaTarih THEN 'Tamamlanacak'
      WHEN g.gDurum != 'Tamamlandı' THEN 'Devam Ediyor'
      ELSE 'Tamamlandı'
    END
    WHERE 1=1`;

  connection.query(query, (err, result) => {
    if (err) {
      console.error('Görev durumları güncellenirken hata:', err);
    } else {
      console.log('Görev durumları güncellendi');
    }
  });
};

// Görevleri ve gecikme sürelerini getirme
app.get('/tasks/:projectId', (req, res) => {
  const projectId = req.params.projectId;
  const query = `
    SELECT 
      g.*, 
      c.cAdSoyad, 
      p.pAd as projeAdi,
      CASE 
        WHEN g.gDurum != 'Tamamlandı' AND CURDATE() > g.gBitisTarih 
        THEN DATEDIFF(CURDATE(), g.gBitisTarih)
        ELSE 0
      END as gecikmeGun
    FROM Gorev g
    JOIN Calisanlar c ON g.Calisanlar_cID = c.cID
    JOIN Proje p ON g.Proje_pID = p.pID
    WHERE g.Proje_pID = ?
  `;
  
  connection.query(query, [projectId], (err, results) => {
    if (err) {
      res.status(500).json({ error: err.message });
      return;
    }
    res.json(results);
  });
});

const scheduleTaskStatusUpdates = () => {
  const now = new Date();
  const night = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate() + 1,
    0, 0, 0
  );
  const timeToMidnight = night - now;

  setTimeout(() => {
    updateTaskStatuses();
    setInterval(updateTaskStatuses, 24 * 60 * 60 * 1000);
  }, timeToMidnight);
};

// Nodejs sunucusu başlatma ve zaman  kontrolcülerini başlatma
app.listen(port, () => {
  console.log(`Node.js sunucusu http://localhost:${port} adresinde çalışıyor`);
  updateTaskStatuses();
  scheduleTaskStatusUpdates();
});

// Global hata yakalayıcısı
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Sunucu hatası',
    details: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});


// Mysql bağlantısı kapatma
process.on('SIGINT', () => {
  connection.end((err) => {
    if (err) {
      console.error('MySQL bağlantısı kapatılırken hata:');
    }
    process.exit();
  });
});