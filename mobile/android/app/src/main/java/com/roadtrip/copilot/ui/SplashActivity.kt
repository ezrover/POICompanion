package com.roadtrip.copilot.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.animation.Animation
import android.view.animation.AnimationUtils
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import com.roadtrip.copilot.MainActivity
import com.roadtrip.copilot.R

class SplashActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)

        val logo: ImageView = findViewById(R.id.splash_logo)
        val rotateAnimation = AnimationUtils.loadAnimation(this, R.anim.rotate)
        logo.startAnimation(rotateAnimation)

        // Simulate model loading with a delay
        Handler(Looper.getMainLooper()).postDelayed({
            // Start the main activity
            startActivity(Intent(this, MainActivity::class.java))
            // Close this activity
            finish()
        }, 3000) // 3 second delay
    }
}
