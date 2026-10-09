import { visit } from 'unist-util-visit';

function slugify(text) {
  return text.normalize('NFKC').trim().toLowerCase().replace(/\.(md|markdown)$/i, '').replace(/[_\s]+/g, '-').replace(/&/g, '-').replace(/[^\p{L}\p{N}-]/gu, '').replace(/-+/g, '-');
}

export function remarkWikiLinks() {
  return (tree) => {
    visit(tree, 'text', (node, index, parent) => {
      if (!parent || index === undefined || !node.value.includes('[[')) return;
      const regex = /\[\[([^\]]+)\]\]/g;
      const pieces = [];
      let last = 0, match;
      while ((match = regex.exec(node.value)) !== null) {
        if (match.index > last) pieces.push({ type: 'text', value: node.value.slice(last, match.index) });
        const [targetWithAnchor, alias] = match[1].split('|');
        const [target, heading] = targetWithAnchor.split('#');
        const label = alias || target;
        const url = '/notes/' + encodeURIComponent(slugify(target)) + '/' + (heading ? '#' + encodeURIComponent(slugify(heading)) : '');
        pieces.push({ type: 'link', url, children: [{ type: 'text', value: label }] });
        last = regex.lastIndex;
      }
      if (!pieces.length) return;
      if (last < node.value.length) pieces.push({ type: 'text', value: node.value.slice(last) });
      parent.children.splice(index, 1, ...pieces);
      return index + pieces.length;
    });
  };
}
