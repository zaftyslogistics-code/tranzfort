declare namespace Deno {
  namespace env {
    function get(key: string): string | undefined
  }

  function serve(handler: (request: Request) => Response | Promise<Response>): void
}

declare module '@supabase/supabase-js' {
  export function createClient(...args: any[]): any
}
