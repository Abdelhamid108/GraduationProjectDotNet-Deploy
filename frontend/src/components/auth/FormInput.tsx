import type { InputHTMLAttributes } from 'react'
import { forwardRef } from 'react'

import { Input } from '@/components/ui/input'
import { cn } from '@/lib/utils'

type FormInputProps = InputHTMLAttributes<HTMLInputElement> & {
  label: string
  error?: string
}

const FormInput = forwardRef<HTMLInputElement, FormInputProps>(
  ({ label, error, className, id, ...props }, ref) => {
    const inputId = id ?? label.replace(/\s+/g, '-').toLowerCase()

    return (
      <div className="flex flex-col items-end gap-1.5 px-1 w-full">
        <label
          htmlFor={inputId}
          className="w-full text-right text-base font-normal leading-[30px] text-[#1A156C]"
        >
          {label}
        </label>
        <Input
          ref={ref}
          id={inputId}
          className={cn('w-full', className)}
          {...props}
        />
        {error && (
          <span className="text-sm text-red-500 text-right">{error}</span>
        )}
      </div>
    )
  }
)
FormInput.displayName = 'FormInput'

export { FormInput }
