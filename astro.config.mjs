// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://docs.sporhq.io',
	integrations: [
		starlight({
			title: 'Spor',
			description:
				'Documentation for Spor — a typed, versioned knowledge graph of the durable outcomes of work.',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/sporhq/spor' },
			],
			customCss: ['./src/styles/tokens.css', './src/styles/theme.css'],
			head: [
				{
					// The canonical Spor tokens key dark mode on `html.dark`;
					// Starlight toggles `data-theme`. Mirror the attribute onto the
					// class so the vendored tokens.css stays byte-identical.
					tag: 'script',
					content:
						"(function(){var h=document.documentElement,s=function(){h.classList.toggle('dark',h.getAttribute('data-theme')==='dark')};new MutationObserver(s).observe(h,{attributes:true,attributeFilter:['data-theme']});s();})();",
				},
			],
			sidebar: [
				{ label: 'Getting started', items: [{ autogenerate: { directory: 'getting-started' } }] },
				{ label: 'Concepts', items: [{ autogenerate: { directory: 'concepts' } }] },
				{ label: 'CLI reference', items: [{ autogenerate: { directory: 'cli' } }] },
				{ label: 'REST API', items: [{ autogenerate: { directory: 'api' } }] },
				{ label: 'MCP', items: [{ autogenerate: { directory: 'mcp' } }] },
				{ label: 'Hosted Spor', items: [{ autogenerate: { directory: 'hosted' } }] },
			],
		}),
	],
});
