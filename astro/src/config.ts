import type { ExpressiveCodeConfig, LicenseConfig, NavBarConfig, ProfileConfig, SiteConfig } from "./types/config";
import { LinkPreset } from "./types/config";

export const siteConfig: SiteConfig = {
  title: "羽落天青 | Uke's Blog",
  subtitle: "",
  lang: "zh_CN",
  themeColor: { hue: 210, fixed: true },
  banner: {
    enable: false,
    src: "/wallpapers/user-night-desk.avif",
    position: "center",
    credit: { enable: false, text: "", url: "" },
  },
  toc: { enable: true, depth: 3 },
  favicon: [{ src: "/assets/img/branding/MVM.ico", sizes: "any" }],
};

export const navBarConfig: NavBarConfig = {
  links: [
    LinkPreset.Home,
    { name: "文章", url: "/writing/" },
    { name: "笔记花园", url: "/notes/" },
    { name: "项目", url: "/projects/" },
    LinkPreset.Archive,
    LinkPreset.About,
    { name: "GitHub", url: "https://github.com/Tiany1Yu", external: true },
  ],
};

export const profileConfig: ProfileConfig = {
  avatar: "/assets/img/Myself.jpg",
  name: "uke",
  bio: "南京大学 | 智能科学与技术",
  links: [
    { name: "GitHub", icon: "fa6-brands:github", url: "https://github.com/Tiany1Yu" },
  ],
};

export const licenseConfig: LicenseConfig = {
  enable: false,
  name: "",
  url: "",
};

export const expressiveCodeConfig: ExpressiveCodeConfig = {
  theme: "github-dark",
};
