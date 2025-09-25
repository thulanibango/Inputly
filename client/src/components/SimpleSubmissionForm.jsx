import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Button } from './ui/button'
import { Input } from './ui/input'
import { Card } from './ui/card'

export function SimpleSubmissionForm() {
  const [inputText, setInputText] = useState('')
  const [submissions, setSubmissions] = useState([])
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Fetch last 5 submissions on component mount
  useEffect(() => {
    fetchSubmissions()
  }, [])

  const fetchSubmissions = async () => {
    try {
      const response = await fetch('/api/submissions')
      if (response.ok) {
        const data = await response.json()
        setSubmissions(data)
      }
    } catch (error) {
      console.error('Error fetching submissions:', error)
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!inputText.trim()) return

    setIsSubmitting(true)
    try {
      const response = await fetch('/api/submissions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ text: inputText }),
      })

      if (response.ok) {
        setInputText('')
        await fetchSubmissions() // Refresh the list
      }
    } catch (error) {
      console.error('Error submitting:', error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen gradient-bg-dark p-6">
      <div className="max-w-2xl mx-auto">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <Card className="glass-card p-8 mb-8">
            <h1 className="text-3xl font-bold text-center mb-8 text-white">
              Simple Text Submission
            </h1>
            
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <Input
                  type="text"
                  placeholder="Enter your text here..."
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  className="glass-input text-lg py-3"
                />
              </div>
              
              <Button 
                type="submit" 
                className="w-full glass-button text-lg py-3"
                disabled={isSubmitting || !inputText.trim()}
              >
                {isSubmitting ? 'Submitting...' : 'Submit'}
              </Button>
            </form>
          </Card>

          {/* Display Last 5 Submissions */}
          <Card className="glass-card p-8">
            <h2 className="text-2xl font-semibold mb-6 text-white">
              Last 5 Submissions
            </h2>
            
            {submissions.length === 0 ? (
              <p className="text-white/60 text-center py-8">
                No submissions yet. Be the first to submit!
              </p>
            ) : (
              <div className="space-y-4">
                {submissions.map((submission, index) => (
                  <motion.div
                    key={submission.id}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="bg-white/10 backdrop-blur-sm rounded-lg p-4 border border-white/20"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <span className="text-white font-medium">
                        #{submissions.length - index}
                      </span>
                      <span className="text-white/60 text-sm">
                        {new Date(submission.created_at).toLocaleString()}
                      </span>
                    </div>
                    <p className="text-white break-words">{submission.text}</p>
                  </motion.div>
                ))}
              </div>
            )}
          </Card>
        </motion.div>
      </div>
    </div>
  )
}