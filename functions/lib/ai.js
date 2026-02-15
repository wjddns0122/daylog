"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateCurationAndMusic = void 0;
const axios_1 = require("axios");
const vertexai_1 = require("@google-cloud/vertexai");
const googleapis_1 = require("googleapis");
const DEFAULT_CURATION = "A quiet moment, held gently in time.";
const DEFAULT_MUSIC_QUERY = "calm ambient instrumental";
const DEFAULT_YOUTUBE_URL = "https://www.youtube.com/watch?v=5qap5aO4i9A";
const DEFAULT_YOUTUBE_TITLE = "lofi hip hop radio - beats to relax/study to";
const AI_BYPASS = process.env.AI_BYPASS === "true";
const CURATION_PROMPT = [
    "You are an assistant for emotional curation from photos.",
    "Analyze the image and return only JSON.",
    "Fields:",
    "1) curation: sentiment description (curation) in 1-2 natural sentences.",
    "2) musicQuery: concise search query for background music on YouTube.",
    'Output schema: {"curation": string, "musicQuery": string}',
].join("\n");
const cleanJsonBlock = (rawText) => {
    return rawText.replace(/```json|```/g, "").trim();
};
const parseModelOutput = (rawText) => {
    try {
        const parsed = JSON.parse(cleanJsonBlock(rawText));
        if (!parsed.curation || !parsed.musicQuery) {
            return null;
        }
        return {
            curation: parsed.curation.trim(),
            musicQuery: parsed.musicQuery.trim(),
        };
    }
    catch (_a) {
        return null;
    }
};
const fetchImageAsBase64 = async (imageUrl) => {
    const response = await axios_1.default.get(imageUrl, {
        responseType: "arraybuffer",
        timeout: 10000,
    });
    const contentType = response.headers["content-type"];
    const mimeType = typeof contentType === "string" ? contentType : "image/jpeg";
    return {
        data: Buffer.from(response.data).toString("base64"),
        mimeType,
    };
};
const analyzeWithVertex = async (imageBase64, mimeType) => {
    var _a, _b, _c, _d, _e;
    const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
    const location = process.env.VERTEX_LOCATION || "us-central1";
    if (!project) {
        return null;
    }
    try {
        const vertexAI = new vertexai_1.VertexAI({ project, location });
        const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash" });
        const result = await model.generateContent({
            contents: [
                {
                    role: "user",
                    parts: [
                        { text: CURATION_PROMPT },
                        {
                            inlineData: {
                                data: imageBase64,
                                mimeType,
                            },
                        },
                    ],
                },
            ],
        });
        const text = (_e = (_d = (_c = (_b = (_a = result.response.candidates) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.content) === null || _c === void 0 ? void 0 : _c.parts) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.text;
        if (!text) {
            return null;
        }
        return parseModelOutput(text);
    }
    catch (error) {
        console.error("Vertex AI analysis failed:", error);
        return null;
    }
};
const analyzeWithGeminiApiKey = async (imageBase64, mimeType) => {
    var _a, _b, _c, _d, _e, _f;
    const geminiApiKey = process.env.GEMINI_API_KEY;
    if (!geminiApiKey) {
        return null;
    }
    try {
        const response = await axios_1.default.post("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent", {
            contents: [
                {
                    role: "user",
                    parts: [
                        { text: CURATION_PROMPT },
                        {
                            inlineData: {
                                data: imageBase64,
                                mimeType,
                            },
                        },
                    ],
                },
            ],
        }, {
            params: { key: geminiApiKey },
            timeout: 15000,
        });
        const text = (_f = (_e = (_d = (_c = (_b = (_a = response.data) === null || _a === void 0 ? void 0 : _a.candidates) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.content) === null || _d === void 0 ? void 0 : _d.parts) === null || _e === void 0 ? void 0 : _e[0]) === null || _f === void 0 ? void 0 : _f.text;
        if (typeof text !== "string") {
            return null;
        }
        return parseModelOutput(text);
    }
    catch (error) {
        console.error("Gemini API key analysis failed:", error);
        return null;
    }
};
const searchYouTubeMusic = async (query) => {
    var _a, _b;
    const youtubeApiKey = process.env.YOUTUBE_API_KEY;
    if (!youtubeApiKey) {
        return {
            youtubeUrl: DEFAULT_YOUTUBE_URL,
            youtubeTitle: DEFAULT_YOUTUBE_TITLE,
        };
    }
    try {
        const youtube = googleapis_1.google.youtube({ version: "v3", auth: youtubeApiKey });
        const response = await youtube.search.list({
            part: ["snippet"],
            type: ["video"],
            maxResults: 1,
            q: query,
            safeSearch: "strict",
        });
        if (!response.data.items || response.data.items.length === 0) {
            return {
                youtubeUrl: DEFAULT_YOUTUBE_URL,
                youtubeTitle: DEFAULT_YOUTUBE_TITLE,
            };
        }
        const firstItem = response.data.items[0];
        const videoId = (_a = firstItem.id) === null || _a === void 0 ? void 0 : _a.videoId;
        const title = (_b = firstItem.snippet) === null || _b === void 0 ? void 0 : _b.title;
        if (!videoId || !title) {
            return {
                youtubeUrl: DEFAULT_YOUTUBE_URL,
                youtubeTitle: DEFAULT_YOUTUBE_TITLE,
            };
        }
        return {
            youtubeUrl: `https://www.youtube.com/watch?v=${videoId}`,
            youtubeTitle: title,
        };
    }
    catch (error) {
        console.error("YouTube search failed:", error);
        return {
            youtubeUrl: DEFAULT_YOUTUBE_URL,
            youtubeTitle: DEFAULT_YOUTUBE_TITLE,
        };
    }
};
const generateCurationAndMusic = async (imageUrl) => {
    if (AI_BYPASS) {
        return {
            curation: DEFAULT_CURATION,
            youtubeUrl: DEFAULT_YOUTUBE_URL,
            youtubeTitle: DEFAULT_YOUTUBE_TITLE,
        };
    }
    try {
        const image = await fetchImageAsBase64(imageUrl);
        const modelOutput = (await analyzeWithVertex(image.data, image.mimeType)) ||
            (await analyzeWithGeminiApiKey(image.data, image.mimeType));
        const curation = (modelOutput === null || modelOutput === void 0 ? void 0 : modelOutput.curation) || DEFAULT_CURATION;
        const musicQuery = (modelOutput === null || modelOutput === void 0 ? void 0 : modelOutput.musicQuery) || DEFAULT_MUSIC_QUERY;
        const youtube = await searchYouTubeMusic(musicQuery);
        return {
            curation,
            youtubeUrl: youtube.youtubeUrl,
            youtubeTitle: youtube.youtubeTitle,
        };
    }
    catch (error) {
        console.error("generateCurationAndMusic failed:", error);
        return {
            curation: DEFAULT_CURATION,
            youtubeUrl: DEFAULT_YOUTUBE_URL,
            youtubeTitle: DEFAULT_YOUTUBE_TITLE,
        };
    }
};
exports.generateCurationAndMusic = generateCurationAndMusic;
//# sourceMappingURL=ai.js.map