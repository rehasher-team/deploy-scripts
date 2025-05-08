const http = require('http');

const server = http.createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('OK');
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(3000, () => console.log(`Server is running at http://localhost:3000`));

const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const { readFile, writeFile } = require("fs/promises");
const { exec } = require("child_process");
const { pipeline } = require("stream");
const { promisify } = require("util");

const REGION = "ap-northeast-2";
const BUCKET = "rehash-private-storage";
const KEY = "rehash-backend/version/LATEST";
const LOCAL_PATH = "./LATEST";       // EC2 내 LATEST 파일 경로
const REDEPLOY_CMD = "bash ./redeploy.sh"; // 재배포를 수행하는 스크립트

const s3 = new S3Client({ region: REGION });
const streamToString = async (stream) => {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf-8");
};

async function checkAndRedeploy() {
  try {
    // 1) S3에서 최신 LATEST 내용 읽기
    const { Body } = await s3.send(new GetObjectCommand({
      Bucket: BUCKET,
      Key: KEY,
    }));
    const remote = await streamToString(Body);
    console.log(`Remote LATEST: ${remote}`);

    // 2) 로컬 LATEST 읽기
    let local = "";
    try {
      local = await readFile(LOCAL_PATH, "utf-8");

      console.log(`로컬 LATEST: ${local}`);
    } catch (err) {
      if (err.code !== "ENOENT") throw err;
      // 파일이 없으면 강제로 재배포 처리
      console.log("로컬 LATEST 파일이 없습니다. 새로 생성합니다.");
    }

    // 3) 비교 후 다르면 업데이트 & 재배포
    if (remote.trim() !== local.trim()) {
      console.log(`업데이트 감지: remote=${remote.trim()}, local=${local.trim()}`);
      await writeFile(LOCAL_PATH, remote, "utf-8");
      console.log("로컬 LATEST 파일 업데이트 완료.");

      exec(REDEPLOY_CMD, (error, stdout, stderr) => {
        if (error) {
          console.error(`재배포 실패: ${error.message}`);
          return;
        }
        console.log(`재배포 완료:\n${stdout}`);
        if (stderr) console.error(`stderr: ${stderr}`);
      });
    } else {
      console.log(`변경 없음: remote=${remote.trim()}, local=${local.trim()}`);
    }
  } catch (error) {
    console.error("오류 발생:", error);
  }
}

// 10분마다 실행 (600,000ms)
setInterval(checkAndRedeploy, 10 * 60 * 1000);
