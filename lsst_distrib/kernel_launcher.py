import sys
import os
import runpy
import copy
from typing import List

def reorder_paths(paths: List[str], prefix: str = None) -> List[str]:
   if prefix is None:
      return paths

   head = [p for p in paths if p.startswith(prefix) or p == '']
   tail = [p for p in paths if not p in head]
   return head + tail
 
if __name__ == '__main__':
   sys.path = reorder_paths(sys.path, os.environ.get('CONDA_PREFIX'))
   runpy.run_module('ipykernel_launcher', run_name='__main__')
