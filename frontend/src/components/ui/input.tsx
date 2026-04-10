import * as React from 'react'

import { cn } from '@/lib/utils'

const Input = React.forwardRef<HTMLInputElement, React.ComponentProps<'input'>>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          'flex h-12 w-full rounded-[10px] border border-[#A9A9A9] bg-[#E9F6FC] px-3 py-2 text-right text-sm text-[#A9A9A9] placeholder:text-[#A9A9A9] focus:outline-none focus:ring-2 focus:ring-[#1A156C]/20 focus:border-[#1A156C] disabled:cursor-not-allowed disabled:opacity-50',
          className
        )}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = 'Input'

export { Input }
