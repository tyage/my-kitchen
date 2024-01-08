const { spawn, spawnSync } = require('child_process');
const fs = require('fs');

const input = process.env.INPUT;
const output = process.env.OUTPUT;
const isDualMono = parseInt(process.env.AUDIOCOMPONENTTYPE, 10) == 2;

// for caption decoding
const tmpFile = `${output}.tmp`
const ffmpegArgs = ['-y', '-fix_sub_duration', '-i', input, '-c:v', 'copy', '-c:a', 'copy', '-c:s', 'mov_text', '-f', 'mp4', tmpFile]

const args = [];

// input 設定
Array.prototype.push.apply(args, ['-i', tmpFile]);
// qsv decode
Array.prototype.push.apply(args, ['--avhw']);
// 音声
Array.prototype.push.apply(args, ['--audio-codec', 'aac']);
// コーデック
Array.prototype.push.apply(args, ['-c', 'hevc']);
// エンコード品質と速度のバランスの設定
Array.prototype.push.apply(args, ['-u', 'best']);
// 品質設定 (default: 23)
Array.prototype.push.apply(args, ['--icq', '23']);
// デインタレース
Array.prototype.push.apply(args, ['--vpp-afs', 'preset=anime,24fps=true']);
// copy sub
Array.prototype.push.apply(args, ['--sub-copy']);
// 出力ファイル
Array.prototype.push.apply(args, ['-o', output]);

(async () => {
    // decode caption
    spawnSync('/usr/local/bin/ffmpeg', ffmpegArgs);

    const child = spawn('/usr/bin/qsvencc', args);

    /**
     * エンコード進捗表示用に標準出力に進捗情報を吐き出す
     * 出力する JSON
     * {"type":"progress","percent": 0.8, "log": "view log" }
     */
    child.stdout.on('data', data => {
        console.log(data.toString())
    })
    child.stderr.on('data', data => {
        let strbyline = String(data).split('\n');
        for (let i = 0; i < strbyline.length; i++) {
            let str = strbyline[i];
            if (str.startsWith('[')) {
                // 想定log
                // [89.4%] 51605 frames: 54.27 fps, 4814 kb/s, remain 0:01:53, est out size 1105.4MB
                const progress = {};
                const qsvencc_regex = /\[(?<percent>\d+(?:\.\d+)?)%\]\s*(?<frame>\d+)\s*frames:\s*(?<fps>\d+(?:\.\d+)?)\s*fps,\s*(?<bitrate>\d+(?:\.\d+)?)\s*kb\/s,\s*remain\s*(?<time>\d+[:\.\d+]*)/
                let ffmatch = str.match(qsvencc_regex);
                /**
                 * match結果
                 * [
                 *   '[89.4%] 51605 frames: 54.27 fps, 4814 kb/s, remain 0:01:53, est out size 1105.4MB',
                 *   '89.4',
                 *   '51605',
                 *   '54.27',
                 *   '4814',
                 *   '0:01:53',
                 *   index: 0,
                 *   input: '[89.4%] 51605 frames: 54.27 fps, 4814 kb/s, remain 0:01:53, est out size 1105.4MB',
                 *   groups: [Object: null prototype] {
                 *     bitrate: '4814',
                 *     fps: '54.27',
                 *     frame: '51605',
                 *     percent: '89.4',
                 *     time: '0:01:53'
                 *   }
                 * ]
                 */

                if (ffmatch === null) continue;

                progress['bitrate'] = parseFloat(ffmatch.groups.bitrate);
                progress['fps'] = parseFloat(ffmatch.groups.fps);
                progress['frame'] = parseInt(ffmatch.groups.frame);
                progress['percent'] = parseFloat(ffmatch.groups.percent) / 100;
                progress['time'] = ffmatch.groups.time;

                const log =
                    'frame= ' +
                    progress.frame +
                    ' fps=' +
                    progress.fps +
                    ' time=' +
                    progress.time +
                    ' bitrate=' +
                    progress.bitrate;

                console.log(JSON.stringify({ type: 'progress', percent: progress.percent, log: log }));
            }
        }
    });

    child.on('error', err => {
        console.error(err);
        throw new Error(err);
    });

    process.on('SIGINT', () => {
        child.kill('SIGINT');
        if (fs.existsSync(tmpFile)) {
          fs.unlinkSync(tmpFile);
        }
    });
    process.on('exit', () => {
        if (fs.existsSync(tmpFile)) {
          fs.unlinkSync(tmpFile);
        }
    });
})();
