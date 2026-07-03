import React from 'react';
import ReactMarkdown from 'react-markdown';

export default function MarkdownText({ data }) {
  return (
    <div className="prose prose-sm max-w-none prose-p:my-1 prose-headings:my-2 prose-ul:my-1 prose-li:my-0 text-gray-800">
      <ReactMarkdown>
        {data}
      </ReactMarkdown>
    </div>
  );
}
