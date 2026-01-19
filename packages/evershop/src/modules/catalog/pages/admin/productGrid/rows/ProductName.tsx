import { TableCell } from '@components/common/ui/Table.js';
import React from 'react';

export interface ProductNameRowProps {
  name: string;
  url: string;
}
export function ProductNameRow({ url, name }: ProductNameRowProps) {
  return (
    <TableCell>
      <div>
        <a className="hover:underline font-semibold" href={url}>
          {name}
        </a>
      </div>
    </TableCell>
  );
}
