module FaceApi
  FACE_API_KEY = Rails.env.production? ? "1f7890dd2ba64b820c40dba22626fb9b" : "8e598e8264979fb6a83f46b8c9245d5e"
  FACE_API_SECRET = Rails.env.production? ? "763eadb5bd90833f7d82eca45173f467" : "2538f1cae85215bc4a0d79f9eb908d0a"
end
