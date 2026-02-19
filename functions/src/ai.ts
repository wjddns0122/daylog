import axios from "axios";
import { VertexAI } from "@google-cloud/vertexai";
import { google } from "googleapis";

type CurationModelOutput = {
  curation: string;
  songTitle: string;
  musicReason: string;
  musicQuery: string;
};

type KeywordModelOutput = {
  keywords: string[];
};

type GeneratedAiResult = {
  curation: string;
  youtubeUrl: string;
  youtubeTitle: string;
  songTitle: string;
  musicReason: string;
};

const DEFAULT_CURATION = "고요한 빛이 머무는 순간, 작은 약속처럼 간직됩니다.";
const DEFAULT_SONG_TITLE = "밤편지 - 아이유";
const DEFAULT_MUSIC_REASON =
  "잔잔하고 따뜻한 분위기가 이 사진의 감성과 잘 어울립니다.";
const DEFAULT_MUSIC_QUERY = "아이유 밤편지 official audio";
const DEFAULT_YOUTUBE_URL = "https://www.youtube.com/watch?v=BzYnNdCe-cE";
const DEFAULT_YOUTUBE_TITLE = "아이유(IU) - 밤편지(Through the Night)";
const DEFAULT_KEYWORDS = ["감성적", "따뜻한", "잔잔한", "추억", "평화로운"];
const AI_BYPASS = process.env.AI_BYPASS === "true";

const buildCurationPrompt = (
  moodKeywords: string[],
  caption: string,
): string => {
  const keywordLine =
    moodKeywords.length > 0
      ? `사용자가 선택한 무드 키워드: ${moodKeywords.join(", ")}`
      : "무드 키워드 없음 (사진만으로 판단하세요)";

  const captionLine =
    caption.trim().length > 0
      ? `사용자 캡션: "${caption.trim()}"`
      : "사용자 캡션 없음";

  return [
    "당신은 감성적인 사진 큐레이터입니다.",
    "사진과 아래 정보를 바탕으로 다음을 한국어로 작성하세요.",
    "",
    keywordLine,
    captionLine,
    "",
    "작성 규칙:",
    "1) curation: 사진의 감정과 분위기를 담은 1-2문장의 한국어 큐레이션 문구. 시적이고 감성적으로 작성하세요.",
    "2) songTitle: 사진 무드에 어울리는 대중적인 KPop 또는 Pop 노래 1곡을 추천하세요. '제목 - 아티스트' 형식으로 작성하세요. 많은 사람이 알 만한 유명한 곡을 선택하세요.",
    "3) musicReason: 이 노래를 선정한 이유를 한국어 1-2문장으로 설명하세요.",
    "4) musicQuery: YouTube에서 해당 곡을 검색할 정확한 검색어 (예: '아이유 밤편지 official audio')",
    "",
    "매번 다른 곡을 추천하도록 다양성을 유지하세요.",
    "반드시 아래 JSON 형식으로만 응답하세요:",
    '{"curation": string, "songTitle": string, "musicReason": string, "musicQuery": string}',
  ].join("\n");
};

const KEYWORD_PROMPT = [
  "당신은 사진 분위기 분석 전문가입니다.",
  "사진을 분석하여 분위기와 감정을 나타내는 한국어 키워드를 정확히 5개 제안하세요.",
  "키워드는 형용사 또는 명사로, 예: 잔잔한, 새벽, 감성적, 따뜻한, 추억",
  "반드시 아래 JSON 형식으로만 응답하세요:",
  '{"keywords": ["키워드1", "키워드2", "키워드3", "키워드4", "키워드5"]}',
].join("\n");

const cleanJsonBlock = (rawText: string): string => {
  return rawText.replace(/```json|```/g, "").trim();
};

const parseModelOutput = (rawText: string): CurationModelOutput | null => {
  try {
    const parsed = JSON.parse(
      cleanJsonBlock(rawText),
    ) as Partial<CurationModelOutput>;
    if (!parsed.curation || !parsed.musicQuery) {
      return null;
    }
    return {
      curation: parsed.curation.trim(),
      songTitle: (parsed.songTitle || DEFAULT_SONG_TITLE).trim(),
      musicReason: (parsed.musicReason || DEFAULT_MUSIC_REASON).trim(),
      musicQuery: parsed.musicQuery.trim(),
    };
  } catch {
    return null;
  }
};

const parseKeywordOutput = (rawText: string): KeywordModelOutput | null => {
  try {
    const parsed = JSON.parse(
      cleanJsonBlock(rawText),
    ) as Partial<KeywordModelOutput>;
    if (
      !parsed.keywords ||
      !Array.isArray(parsed.keywords) ||
      parsed.keywords.length === 0
    ) {
      return null;
    }
    return {
      keywords: parsed.keywords
        .filter((k): k is string => typeof k === "string")
        .map((k) => k.trim())
        .slice(0, 5),
    };
  } catch {
    return null;
  }
};

const fetchImageAsBase64 = async (
  imageUrl: string,
): Promise<{ data: string; mimeType: string }> => {
  const response = await axios.get<ArrayBuffer>(imageUrl, {
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

const callGemini = async (
  imageBase64: string,
  mimeType: string,
  prompt: string,
): Promise<string | null> => {
  // Try Vertex AI first
  const project =
    process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  const location = process.env.VERTEX_LOCATION || "us-central1";

  if (project) {
    try {
      const vertexAI = new VertexAI({ project, location });
      const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash" });

      const result = await model.generateContent({
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              { inlineData: { data: imageBase64, mimeType } },
            ],
          },
        ],
      });

      const text = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) return text;
    } catch (error: unknown) {
      const errMsg = error instanceof Error ? error.message : String(error);
      console.warn("Vertex AI failed, trying API key fallback:", errMsg);
    }
  }

  // Fallback: Gemini API Key
  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (!geminiApiKey) return null;

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
      {
        contents: [
          {
            role: "user",
            parts: [
              { text: prompt },
              { inlineData: { data: imageBase64, mimeType } },
            ],
          },
        ],
      },
      { params: { key: geminiApiKey }, timeout: 30000 },
    );

    const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return typeof text === "string" ? text : null;
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      console.warn(
        "Gemini API key fallback failed:",
        error.response?.status,
        error.response?.statusText,
        error.response?.data?.error?.message ?? "",
      );
    } else {
      const errMsg = error instanceof Error ? error.message : String(error);
      console.warn("Gemini API key fallback failed:", errMsg);
    }
    return null;
  }
};

const searchYouTubeMusic = async (
  query: string,
): Promise<{ youtubeUrl: string; youtubeTitle: string }> => {
  const youtubeApiKey = process.env.YOUTUBE_API_KEY;
  if (!youtubeApiKey) {
    return {
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
    };
  }

  try {
    const youtube = google.youtube({ version: "v3", auth: youtubeApiKey });
    const response = await youtube.search.list({
      part: ["snippet"],
      type: ["video"],
      videoCategoryId: "10", // Music category
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
    const videoId = firstItem.id?.videoId;
    const title = firstItem.snippet?.title;

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
  } catch (error) {
    console.error("YouTube search failed:", error);
    return {
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
    };
  }
};

/**
 * Suggest mood keywords from an image (called from Compose Screen).
 */
export const suggestKeywordsFromImage = async (
  imageUrl: string,
): Promise<string[]> => {
  if (AI_BYPASS) {
    return DEFAULT_KEYWORDS;
  }

  try {
    const image = await fetchImageAsBase64(imageUrl);
    const rawText = await callGemini(
      image.data,
      image.mimeType,
      KEYWORD_PROMPT,
    );

    if (!rawText) {
      return DEFAULT_KEYWORDS;
    }

    const parsed = parseKeywordOutput(rawText);
    return parsed?.keywords || DEFAULT_KEYWORDS;
  } catch (error) {
    console.error("suggestKeywordsFromImage failed:", error);
    return DEFAULT_KEYWORDS;
  }
};

/**
 * Generate Korean curation text + single song recommendation.
 */
export const generateCurationAndMusic = async (
  imageUrl: string,
  moodKeywords: string[] = [],
  caption: string = "",
): Promise<GeneratedAiResult> => {
  if (AI_BYPASS) {
    return {
      curation: DEFAULT_CURATION,
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
      songTitle: DEFAULT_SONG_TITLE,
      musicReason: DEFAULT_MUSIC_REASON,
    };
  }

  try {
    const image = await fetchImageAsBase64(imageUrl);
    const prompt = buildCurationPrompt(moodKeywords, caption);
    const rawText = await callGemini(image.data, image.mimeType, prompt);

    const modelOutput = rawText ? parseModelOutput(rawText) : null;

    const curation = modelOutput?.curation || DEFAULT_CURATION;
    const songTitle = modelOutput?.songTitle || DEFAULT_SONG_TITLE;
    const musicReason = modelOutput?.musicReason || DEFAULT_MUSIC_REASON;
    const musicQuery = modelOutput?.musicQuery || DEFAULT_MUSIC_QUERY;
    const youtube = await searchYouTubeMusic(musicQuery);

    return {
      curation,
      youtubeUrl: youtube.youtubeUrl,
      youtubeTitle: youtube.youtubeTitle,
      songTitle,
      musicReason,
    };
  } catch (error) {
    console.error("generateCurationAndMusic failed:", error);

    return {
      curation: DEFAULT_CURATION,
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
      songTitle: DEFAULT_SONG_TITLE,
      musicReason: DEFAULT_MUSIC_REASON,
    };
  }
};
