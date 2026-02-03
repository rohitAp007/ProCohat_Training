import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const { phone } = await req.json()

        // Validate phone number
        if (!phone || phone.length < 10 || phone.length > 15) {
            return new Response(
                JSON.stringify({ error: 'Invalid phone number format' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Create Supabase client with service role
        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // Check rate limiting (max 3 OTPs per phone in 15 min)
        const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString()

        const { data: recentOtps, error: checkError } = await supabase
            .from('phone_otps')
            .select('id')
            .eq('phone_number', phone)
            .gte('created_at', fifteenMinutesAgo)

        if (checkError) {
            console.error('Error checking rate limit:', checkError)
        }

        if (recentOtps && recentOtps.length >= 3) {
            return new Response(
                JSON.stringify({
                    error: 'Too many requests. Please try again in 15 minutes.',
                    retry_after: 900 // 15 minutes in seconds
                }),
                { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Invalidate all previous unverified OTPs for this phone
        await supabase
            .from('phone_otps')
            .update({ verified: true })
            .eq('phone_number', phone)
            .eq('verified', false)

        // Generate 6-digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString()

        // Store OTP (expires in 5 minutes)
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString()

        const { data: otpRecord, error: insertError } = await supabase
            .from('phone_otps')
            .insert({
                phone_number: phone,
                otp_code: otp,
                expires_at: expiresAt
            })
            .select()
            .single()

        if (insertError) {
            console.error('Error inserting OTP:', insertError)
            throw new Error('Failed to generate OTP')
        }

        console.log(`✅ OTP generated for ${phone}: ${otp} (expires at ${expiresAt})`)

        // For development: return OTP in response
        // For production: send via email/webhook
        const isDevelopment = Deno.env.get('ENVIRONMENT') !== 'production'

        return new Response(
            JSON.stringify({
                success: true,
                message: 'OTP sent successfully',
                expires_in: 300, // 5 minutes in seconds
                // Only include OTP in development mode
                ...(isDevelopment && { otp_dev: otp })
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error in generate-otp:', error)
        return new Response(
            JSON.stringify({
                error: error.message || 'Internal server error'
            }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
