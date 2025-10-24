import { useEffect, useState } from 'react'
export default function Toast({ msg, onDone, ms=2500 }) {
  const [show, setShow] = useState(!!msg)
  useEffect(()=>{
    if (msg) {
      setShow(true);
      const t=setTimeout(()=>{setShow(false); onDone?.()}, ms);
      return ()=>clearTimeout(t);
    }
  },[msg])
  if (!show) return null
  return <div style={{
    position:'fixed', bottom:20, right:20, background:'#111', color:'#fff',
    padding:'10px 14px', borderRadius:10, boxShadow:'0 6px 24px rgba(0,0,0,.2)'
  }}>{msg}</div>
}
