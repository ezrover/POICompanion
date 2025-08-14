import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, Share } from 'react-native';

const ReferralDashboard = ({ userId }) => {
  const [referralStats, setReferralStats] = useState(null);
  const [recentReferrals, setRecentReferrals] = useState([]);
  const [referralCode, setReferralCode] = useState(null);

  useEffect(() => {
    const fetchReferralData = async () => {
      try {
        const response = await fetch(`https://your-api-endpoint.com/api/v1/referrals/analytics?userId=${userId}`);
        const data = await response.json();
        setReferralStats(data.user_referral_stats);
        setRecentReferrals(data.recent_referrals);
        setReferralCode(data.user_referral_stats.referral_code); // Assuming the referral code is in the stats
      } catch (error) {
        console.error("Error fetching referral data:", error);
      }
    };

    if (userId) {
      fetchReferralData();
    }
  }, [userId]);

  const onShare = async () => {
    if (!referralCode) {
      alert("Could not get your referral code. Please try again later.");
      return;
    }
    try {
      const result = await Share.share({
        message:
          `Check out Roadtrip-Copilot - discover amazing places and get 7 FREE roadtrips to start! https://roadtrip.app/r/${referralCode}`,
      });
    } catch (error) {
      alert(error.message);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Referral Dashboard</Text>

      {referralStats ? (
        <View style={styles.statsContainer}>
          <Text>Total Referrals: {referralStats.total_referrals_sent}</Text>
          <Text>Successful Referrals: {referralStats.successful_referrals}</Text>
          <Text>Credits Earned: {referralStats.credits_earned}</Text>
        </View>
      ) : (
        <Text>Loading referral stats...</Text>
      )}

      <TouchableOpacity style={styles.shareButton} onPress={onShare}>
        <Text style={styles.shareButtonText}>Share Your Referral Link</Text>
      </TouchableOpacity>

      <Text style={styles.recentReferralsTitle}>Recent Referrals</Text>
      <FlatList
        data={recentReferrals}
        keyExtractor={(item) => item.referral_code}
        renderItem={({ item }) => (
          <View style={styles.referralItem}>
            <Text>Referred: {item.referred_user_name}</Text>
            <Text>Status: {item.status}</Text>
            <Text>Date: {new Date(item.sent_at).toLocaleDateString()}</Text>
          </View>
        )}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 20,
  },
  statsContainer: {
    marginBottom: 20,
  },
  shareButton: {
    backgroundColor: '#007bff',
    padding: 15,
    borderRadius: 5,
    alignItems: 'center',
    marginBottom: 20,
  },
  shareButtonText: {
    color: '#fff',
    fontSize: 16,
  },
  recentReferralsTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  referralItem: {
    padding: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#ccc',
  },
});

export default ReferralDashboard;
