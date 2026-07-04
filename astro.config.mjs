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
						'reference/configuration',
						'reference/costs-and-controls',
						'reference/diagnostics',
					],
				},
				{ label: 'Contributing', items: [{ autogenerate: { directory: 'contributing' } }] },
			],
		}),
	],
	// The launch IA shipped surface-shaped URLs (/getting-started/, /concepts/,
	// /cli/, /api/, /mcp/); every old URL redirects to its journey-shaped home.
	redirects: {
		'/getting-started': '/start-here/',
		'/getting-started/install': '/start-here/install/',
		'/getting-started/local-quickstart': '/start-here/local-quickstart/',
		'/getting-started/hosted-quickstart': '/start-here/hosted-quickstart/',
		'/getting-started/what-happens-automatically': '/start-here/what-happens-automatically/',
		'/getting-started/costs-and-controls': '/reference/costs-and-controls/',
		'/getting-started/diagnostics': '/reference/diagnostics/',
		'/concepts': '/start-here/core-ideas/',
		'/concepts/capture': '/use-spor/capture/',
		'/concepts/queue': '/use-spor/queue/',
		'/concepts/briefings': '/use-spor/briefings/',
		'/concepts/identity': '/use-spor/identity/',
		'/concepts/dispatch': '/use-spor/dispatch/',
		'/concepts/nodes': '/reference/graph-model/nodes/',
		'/concepts/node-types': '/reference/graph-model/node-types/',
		'/concepts/edges': '/reference/graph-model/edges/',
		'/concepts/schemas': '/reference/graph-model/schemas/',
		'/concepts/local-and-remote': '/reference/graph-model/local-and-remote/',
		'/concepts/claims': '/reference/graph-model/claims/',
		'/concepts/lenses-and-workflows': '/reference/graph-model/lenses-and-workflows/',
		'/concepts/repos-and-projects': '/reference/graph-model/repos-and-projects/',
		'/cli': '/reference/cli/',
		'/cli/getting-started': '/reference/cli/getting-started/',
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
		'/style-guide': '/contributing/style-guide/',
	},
});
