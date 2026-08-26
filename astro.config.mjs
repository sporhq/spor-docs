// @ts-check
import { writeFile } from 'node:fs/promises';
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';

// The launch IA shipped surface-shaped URLs (/getting-started/, /concepts/,
// /cli/, /api/, /mcp/); every old URL redirects to its journey-shaped home.
// This is the single source of truth for moved URLs: it drives both Astro's
// own `redirects` config below (meta-refresh stub pages, so any host still
// gets a working redirect) and the generated Cloudflare `_redirects` file
// (real 301s, for SEO and link equity on docs.sporhq.io). One list, two
// outputs -- they cannot drift.
const redirects = {
	'/getting-started': '/start-here/',
	'/getting-started/install': '/start-here/try-spor-locally/',
	'/getting-started/local-quickstart': '/start-here/try-spor-locally/',
	'/getting-started/hosted-quickstart': '/start-here/invited-to-hosted-spor/',
	'/getting-started/what-happens-automatically': '/use-spor/what-happens-automatically/',
	// The launch-era Start here pages dissolved into three entry paths
	// (try locally / invited to hosted / connect an assistant).
	'/start-here/install': '/start-here/try-spor-locally/',
	'/start-here/local-quickstart': '/start-here/try-spor-locally/',
	'/start-here/hosted-quickstart': '/start-here/invited-to-hosted-spor/',
	'/start-here/what-happens-automatically': '/use-spor/what-happens-automatically/',
	'/getting-started/costs-and-controls': '/reference/costs-and-controls/',
	'/getting-started/diagnostics': '/reference/diagnostics/',
	'/concepts': '/start-here/core-ideas/',
	'/concepts/capture': '/use-spor/capture/',
	'/concepts/queue': '/use-spor/queue/',
	'/concepts/briefings': '/use-spor/briefings/',
	'/concepts/identity': '/use-spor/identity/',
	'/concepts/dispatch': '/reference/dispatch/',
	'/concepts/nodes': '/reference/graph-model/nodes/',
	'/concepts/node-types': '/reference/graph-model/node-types/',
	'/concepts/edges': '/reference/graph-model/edges/',
	'/concepts/schemas': '/reference/graph-model/schemas/',
	'/concepts/local-and-remote': '/reference/graph-model/local-and-remote/',
	'/concepts/claims': '/reference/graph-model/claims/',
	'/concepts/lenses-and-workflows': '/reference/graph-model/lenses-and-workflows/',
	'/concepts/repos-and-projects': '/reference/graph-model/repos-and-projects/',
	'/cli': '/reference/cli/',
	'/cli/getting-started': '/reference/cli/setup-and-identity/',
	// The page landed at /reference/cli/getting-started/ in the IA
	// restructure and was renamed — the slug read like a tutorial.
	'/reference/cli/getting-started': '/reference/cli/setup-and-identity/',
	'/cli/team-admin': '/reference/cli/team-admin/',
	'/cli/reading-the-graph': '/reference/cli/reading-the-graph/',
	'/cli/writing-to-the-graph': '/reference/cli/writing-to-the-graph/',
	'/cli/repo-scoping': '/reference/cli/repo-scoping/',
	'/cli/dispatch': '/reference/cli/dispatch/',
	'/cli/utilities': '/reference/cli/utilities/',
	'/cli/configuration': '/reference/configuration/',
	'/api': '/reference/api/',
	'/api/authentication': '/reference/api/authentication/',
	'/api/reads': '/reference/api/reads/',
	'/api/writes': '/reference/api/writes/',
	'/api/leases': '/reference/api/leases/',
	'/api/lenses-and-sharing': '/reference/api/lenses-and-sharing/',
	'/api/tokens-and-agents': '/reference/api/tokens-and-agents/',
	'/api/workflow-runs': '/reference/api/workflow-runs/',
	'/api/errors-and-compatibility': '/reference/api/errors-and-compatibility/',
	'/mcp': '/reference/mcp/',
	'/mcp/connecting': '/start-here/connect-an-assistant/',
	'/mcp/operating-loop': '/reference/mcp/operating-loop/',
	'/mcp/tools': '/reference/mcp/tools/',
	'/mcp/widget': '/reference/mcp/widget/',
	// Concepts tiering: dispatch is learn-later material, moved from the
	// beginner path (Use Spor) into Reference.
	'/use-spor/dispatch': '/reference/dispatch/',
	'/style-guide': '/contributing/style-guide/',
	// Wake-on-request was demoted from a standalone hosted page to a
	// troubleshooting entry on the diagnostics page.
	'/hosted/wake-on-request': '/reference/diagnostics/#slow-first-request-after-an-idle-period',
	// "Your data" was reshaped into the question-driven data, privacy,
	// and export page.
	'/hosted/your-data': '/hosted/data-privacy-and-export/',
};

// docs.sporhq.io deploys to Cloudflare Pages (see .github/workflows/ci.yml),
// which serves a `_redirects` file in the build output as real HTTP redirects
// -- unlike Astro's own `redirects` config, which (with no adapter, in static
// output mode) can only emit a meta-refresh HTML stub served with a 200.
// Generate that file from the same `redirects` map above so the moved-URL
// list has exactly one source of truth. (String destinations only, matching
// what scripts/check-redirects.sh's lint accepts -- Astro's object-form
// `{ destination, status }` entries aren't needed here and would silently
// fail that lint, so support for them is intentionally left out rather than
// half-added.)
function cloudflareRedirects() {
	return {
		name: 'cloudflare-redirects',
		hooks: {
			/** @param {{ dir: URL }} options */
			'astro:build:done': async ({ dir }) => {
				const lines = Object.entries(redirects).flatMap(([source, destination]) => {
					// Astro's default `trailingSlash: 'ignore'` treats `/foo` and
					// `/foo/` as the same route, but Cloudflare's `_redirects`
					// source matching is literal -- emit both forms so a visitor
					// landing on either gets a real 301 instead of falling through
					// to the static build output (the meta-refresh stub).
					const bare = source.replace(/\/$/, '') || '/';
					const slashed = bare === '/' ? bare : `${bare}/`;
					const sources = bare === slashed ? [bare] : [bare, slashed];
					return sources.map((s) => `${s}  ${destination}  301`);
				});
				await writeFile(new URL('_redirects', dir), lines.join('\n') + '\n', 'utf8');
			},
		},
	};
}

// https://astro.build/config
export default defineConfig({
	site: 'https://docs.sporhq.io',
	integrations: [
		starlight({
			title: 'Spor',
			description:
				'Documentation for Spor, which keeps the decisions, tasks, questions, rules, and notes behind your work in one shared record.',
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
				{ label: 'Start here', items: [{ autogenerate: { directory: 'start-here' } }] },
				{ label: 'Use Spor', items: [{ autogenerate: { directory: 'use-spor' } }] },
				{ label: 'Hosted Spor', items: [{ autogenerate: { directory: 'hosted' } }] },
				{
					label: 'Reference',
					items: [
						{ label: 'CLI', items: [{ autogenerate: { directory: 'reference/cli' } }] },
						{ label: 'MCP', items: [{ autogenerate: { directory: 'reference/mcp' } }] },
						{ label: 'REST API', items: [{ autogenerate: { directory: 'reference/api' } }] },
						{
							label: 'Schema and graph model',
							items: [{ autogenerate: { directory: 'reference/graph-model' } }],
						},
						'reference/dispatch',
						'reference/worker-protocol',
						'reference/configuration',
						'reference/costs-and-controls',
						'reference/diagnostics',
					],
				},
				{ label: 'Contributing', items: [{ autogenerate: { directory: 'contributing' } }] },
			],
			plugins: [starlightLinksValidator()],
		}),
		cloudflareRedirects(),
	],
	redirects,
});
