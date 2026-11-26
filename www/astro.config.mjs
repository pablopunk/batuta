import { defineConfig } from "astro/config";
import react from "@astrojs/react";

export default defineConfig({
  site: "https://batuta.pablopunk.com",
  integrations: [react()],
  devToolbar: { enabled: false },
});
