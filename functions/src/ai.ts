import axios from "axios";
import { VertexAI } from "@google-cloud/vertexai";
import { google } from "googleapis";

type CurationModelOutput = {
  curation: string;
  musicQuery: string;
};

type GeneratedAiResult = {
  curation: string;
  youtubeUrl: string;
  youtubeTitle: string;
};

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
      musicQuery: parsed.musicQuery.trim(),
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

const analyzeWithVertex = async (
  imageBase64: string,
  mimeType: string,
): Promise<CurationModelOutput | null> => {
  const project =
    process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  const location = process.env.VERTEX_LOCATION || "us-central1";

  if (!project) {
    return null;
  }

  try {
    const vertexAI = new VertexAI({ project, location });
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

    const text = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return null;
    }

    return parseModelOutput(text);
  } catch (error) {
    console.error("Vertex AI analysis failed:", error);
    return null;
  }
};

const analyzeWithGeminiApiKey = async (
  imageBase64: string,
  mimeType: string,
): Promise<CurationModelOutput | null> => {
  const geminiApiKey = process.env.GEMINI_API_KEY;
  if (!geminiApiKey) {
    return null;
  }

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent",
      {
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
      },
      {
        params: { key: geminiApiKey },
        timeout: 15000,
      },
    );

    const text = response.data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (typeof text !== "string") {
      return null;
    }

    return parseModelOutput(text);
  } catch (error) {
    console.error("Gemini API key analysis failed:", error);
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

export const generateCurationAndMusic = async (
  imageUrl: string,
): Promise<GeneratedAiResult> => {
  if (AI_BYPASS) {
    return {
      curation: DEFAULT_CURATION,
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
    };
  }

  try {
    const image = await fetchImageAsBase64(imageUrl);

    const modelOutput =
      (await analyzeWithVertex(image.data, image.mimeType)) ||
      (await analyzeWithGeminiApiKey(image.data, image.mimeType));

    const curation = modelOutput?.curation || DEFAULT_CURATION;
    const musicQuery = modelOutput?.musicQuery || DEFAULT_MUSIC_QUERY;
    const youtube = await searchYouTubeMusic(musicQuery);

    return {
      curation,
      youtubeUrl: youtube.youtubeUrl,
      youtubeTitle: youtube.youtubeTitle,
    };
  } catch (error) {
    console.error("generateCurationAndMusic failed:", error);

    return {
      curation: DEFAULT_CURATION,
      youtubeUrl: DEFAULT_YOUTUBE_URL,
      youtubeTitle: DEFAULT_YOUTUBE_TITLE,
    };
  }
};
