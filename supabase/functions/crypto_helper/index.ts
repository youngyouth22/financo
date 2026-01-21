const ENCRYPTION_KEY = Deno.env.get("ENCRYPTION_KEY")!;

// Vérification de sécurité au démarrage
if (!ENCRYPTION_KEY || ENCRYPTION_KEY.length !== 32) {
  throw new Error("ENCRYPTION_KEY must be exactly 32 characters long.");
}

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export async function encryptToken(plainText: string) {
  const iv = crypto.getRandomValues(new Uint8Array(12)); // IV recommandé pour GCM
  const encodedKey = encoder.encode(ENCRYPTION_KEY);
  
  const key = await crypto.subtle.importKey(
    "raw", encodedKey, "AES-GCM", false, ["encrypt"]
  );

  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv },
    key,
    encoder.encode(plainText)
  );

  return {
    // Utilisation de Uint8Array + btoa pour stocker en base64 dans Supabase
    encryptedToken: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv))
  };
}

export async function decryptToken(encryptedToken: string, iv: string) {
  const encodedKey = encoder.encode(ENCRYPTION_KEY);
  const key = await crypto.subtle.importKey(
    "raw", encodedKey, "AES-GCM", false, ["decrypt"]
  );

  const decrypted = await crypto.subtle.decrypt(
    { 
      name: "AES-GCM", 
      iv: Uint8Array.from(atob(iv), c => c.charCodeAt(0)) 
    },
    key,
    Uint8Array.from(atob(encryptedToken), c => c.charCodeAt(0))
  );

  return decoder.decode(decrypted);
}

// // 1. Récupérer les données cryptées
// const { data: connection } = await supabase
//   .from("bank_connections")
//   .select("access_token, iv, user_id")
//   .eq("item_id", item_id)
//   .single();

// // 2. Décrypter
// const realAccessToken = await decryptToken(connection.access_token, connection.iv);

// // 3. Appeler Plaid avec le vrai token
// const plaidRes = await fetch("...", {
//     body: JSON.stringify({ access_token: realAccessToken, ... })
// });