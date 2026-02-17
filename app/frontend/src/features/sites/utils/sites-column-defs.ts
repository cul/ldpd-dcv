
import { createColumnHelper } from "@tanstack/react-table";

import { Site } from "@/types/api";


const columnHelper = createColumnHelper<Site>();

export const columnDefs = [
  columnHelper.accessor('title', {
    header: 'Site Title',
    cell: (info) => info.getValue(),
  }),
  columnHelper.accessor('slug', {
    header: 'slug',
    cell: (info) => info.getValue(),
  })
]