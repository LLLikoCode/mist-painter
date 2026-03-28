/**
 * 生成人造装饰元素tileset
 * 迷雾绘者项目 - 32x32像素风格
 * 复古纸张色调palette
 */

const fs = require('fs');
const zlib = require('zlib');

// 复古纸张色调palette (RGBA)
const COLORS = {
    transparent: [0, 0, 0, 0],
    paper_light: [245, 235, 220, 255],
    paper: [232, 220, 200, 255],
    paper_dark: [200, 185, 165, 255],
    wood_light: [194, 162, 128, 255],
    wood: [160, 120, 90, 255],
    wood_dark: [120, 85, 60, 255],
    metal_light: [180, 180, 190, 255],
    metal: [140, 140, 150, 255],
    metal_dark: [100, 100, 110, 255],
    iron: [80, 80, 90, 255],
    iron_dark: [50, 50, 60, 255],
    gold: [200, 170, 90, 255],
    gold_dark: [160, 130, 60, 255],
    stone: [160, 155, 145, 255],
    stone_dark: [120, 115, 105, 255],
    red: [180, 80, 70, 255],
    blue: [70, 100, 150, 255],
    green: [80, 130, 80, 255],
    black: [40, 40, 45, 255],
    yellow: [220, 200, 100, 255],
    yellow_dark: [180, 160, 60, 255],
    light_glow: [255, 220, 150, 200],
    led_glow: [240, 250, 255, 220],
    water: [100, 140, 200, 255],
};

class PixelImage {
    constructor(width = 32, height = 32) {
        this.width = width;
        this.height = height;
        this.data = Buffer.alloc(width * height * 4, 0);
    }

    setPixel(x, y, color) {
        if (x >= 0 && x < this.width && y >= 0 && y < this.height) {
            const idx = (y * this.width + x) * 4;
            this.data[idx] = color[0];
            this.data[idx + 1] = color[1];
            this.data[idx + 2] = color[2];
            this.data[idx + 3] = color[3];
        }
    }

    fillRect(x1, y1, x2, y2, color) {
        for (let y = y1; y < y2; y++) {
            for (let x = x1; x < x2; x++) {
                this.setPixel(x, y, color);
            }
        }
    }

    drawLine(x1, y1, x2, y2, color) {
        const dx = Math.abs(x2 - x1);
        const dy = Math.abs(y2 - y1);
        const sx = x1 < x2 ? 1 : -1;
        const sy = y1 < y2 ? 1 : -1;
        let err = dx - dy;
        while (true) {
            this.setPixel(x1, y1, color);
            if (x1 === x2 && y1 === y2) break;
            const e2 = 2 * err;
            if (e2 > -dy) { err -= dy; x1 += sx; }
            if (e2 < dx) { err += dx; y1 += sy; }
        }
    }

    toPNG() {
        return createPNG(this.width, this.height, this.data);
    }
}

function crc32(buf) {
    let crc = -1;
    const table = new Uint32Array(256);
    for (let i = 0; i < 256; i++) {
        let c = i;
        for (let j = 0; j < 8; j++) {
            c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
        }
        table[i] = c;
    }
    for (let i = 0; i < buf.length; i++) {
        crc = table[(crc ^ buf[i]) & 0xFF] ^ (crc >>> 8);
    }
    return crc ^ -1;
}

function writeChunk(type, data) {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length, 0);
    const typeBuf = Buffer.from(type, 'ascii');
    const chunk = Buffer.concat([len, typeBuf, data]);
    const crcBuf = Buffer.alloc(4);
    crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
    return Buffer.concat([chunk, crcBuf]);
}

function createPNG(width, height, data) {
    const rowSize = width * 4 + 1;
    const rawData = Buffer.alloc(height * rowSize);
    for (let y = 0; y < height; y++) {
        rawData[y * rowSize] = 0;
        for (let x = 0; x < width; x++) {
            const srcIdx = (y * width + x) * 4;
            const dstIdx = y * rowSize + 1 + x * 4;
            rawData[dstIdx] = data[srcIdx];
            rawData[dstIdx + 1] = data[srcIdx + 1];
            rawData[dstIdx + 2] = data[srcIdx + 2];
            rawData[dstIdx + 3] = data[srcIdx + 3];
        }
    }
    const compressed = zlib.deflateSync(rawData);
    const signature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(width, 0);
    ihdr.writeUInt32BE(height, 4);
    ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
    return Buffer.concat([
        signature,
        writeChunk('IHDR', ihdr),
        writeChunk('IDAT', compressed),
        writeChunk('IEND', Buffer.alloc(0))
    ]);
}

// ============ 路灯/街灯 ============
function createLampClassical() {
    const img = new PixelImage();
    img.fillRect(15, 12, 17, 30, COLORS.iron);
    img.fillRect(14, 14, 15, 16, COLORS.iron_dark);
    img.fillRect(17, 14, 18, 16, COLORS.iron_dark);
    img.fillRect(13, 28, 19, 31, COLORS.iron_dark);
    img.fillRect(14, 27, 18, 28, COLORS.iron);
    img.fillRect(12, 8, 20, 12, COLORS.iron);
    img.fillRect(11, 7, 21, 8, COLORS.iron_dark);
    img.fillRect(13, 9, 19, 11, COLORS.light_glow);
    img.drawLine(15, 7, 16, 4, COLORS.iron);
    img.setPixel(16, 4, COLORS.gold);
    img.setPixel(12, 12, COLORS.gold);
    img.setPixel(19, 12, COLORS.gold);
    return img;
}

function createLampModern() {
    const img = new PixelImage();
    img.fillRect(15, 10, 17, 30, COLORS.metal);
    img.setPixel(16, 15, COLORS.metal_light);
    img.setPixel(16, 20, COLORS.metal_light);
    img.setPixel(16, 25, COLORS.metal_light);
    img.fillRect(14, 28, 18, 31, COLORS.metal_dark);
    img.fillRect(11, 6, 21, 10, COLORS.metal_dark);
    img.fillRect(12, 7, 20, 9, COLORS.metal);
    img.fillRect(13, 8, 19, 9, COLORS.led_glow);
    img.fillRect(12, 4, 20, 6, COLORS.iron_dark);
    img.setPixel(14, 5, COLORS.metal_dark);
    img.setPixel(17, 5, COLORS.metal_dark);
    return img;
}

// ============ 长椅 ============
function createBenchHorizontal() {
    const img = new PixelImage();
    img.fillRect(4, 24, 6, 30, COLORS.iron_dark);
    img.fillRect(26, 24, 28, 30, COLORS.iron_dark);
    img.fillRect(4, 20, 5, 24, COLORS.iron);
    img.fillRect(27, 20, 28, 24, COLORS.iron);
    img.fillRect(3, 22, 29, 24, COLORS.wood);
    img.fillRect(3, 20, 29, 22, COLORS.wood_light);
    for (let x = 5; x < 28; x += 4) {
        img.setPixel(x, 21, COLORS.wood_dark);
        img.setPixel(x, 23, COLORS.wood_dark);
    }
    img.fillRect(4, 12, 5, 20, COLORS.iron);
    img.fillRect(27, 12, 28, 20, COLORS.iron);
    img.fillRect(3, 14, 29, 16, COLORS.wood);
    img.fillRect(3, 11, 29, 14, COLORS.wood_light);
    for (let x = 5; x < 28; x += 4) {
        img.setPixel(x, 12, COLORS.wood_dark);
        img.setPixel(x, 15, COLORS.wood_dark);
    }
    return img;
}

function createBenchVertical() {
    const img = new PixelImage();
    img.fillRect(8, 24, 10, 30, COLORS.iron_dark);
    img.fillRect(22, 24, 24, 30, COLORS.iron_dark);
    img.fillRect(6, 22, 26, 24, COLORS.wood);
    img.fillRect(6, 20, 26, 22, COLORS.wood_light);
    img.setPixel(7, 21, COLORS.wood_dark);
    img.setPixel(25, 21, COLORS.wood_dark);
    img.fillRect(8, 12, 10, 20, COLORS.iron);
    img.fillRect(22, 12, 24, 20, COLORS.iron);
    img.fillRect(6, 14, 26, 16, COLORS.wood);
    img.fillRect(6, 11, 26, 14, COLORS.wood_light);
    img.fillRect(7, 9, 25, 11, COLORS.wood);
    return img;
}

// ============ 标牌/指示牌 ============
function createSignWooden() {
    const img = new PixelImage();
    img.fillRect(15, 18, 17, 31, COLORS.wood_dark);
    img.fillRect(4, 8, 28, 18, COLORS.wood);
    img.fillRect(5, 9, 27, 17, COLORS.wood_light);
    img.fillRect(4, 8, 28, 9, COLORS.wood_dark);
    img.fillRect(4, 17, 28, 18, COLORS.wood_dark);
    img.fillRect(4, 8, 5, 18, COLORS.wood_dark);
    img.fillRect(27, 8, 28, 18, COLORS.wood_dark);
    for (let x = 7; x < 26; x += 3) {
        img.setPixel(x, 11, COLORS.wood_dark);
        img.setPixel(x + 1, 14, COLORS.wood_dark);
    }
    img.drawLine(10, 13, 18, 13, COLORS.wood_dark);
    img.setPixel(17, 12, COLORS.wood_dark);
    img.setPixel(17, 14, COLORS.wood_dark);
    img.setPixel(18, 11, COLORS.wood_dark);
    img.setPixel(18, 15, COLORS.wood_dark);
    return img;
}

function createSignMetal() {
    const img = new Pixel